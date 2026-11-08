# SPDX-License-Identifier: GPL-3.0-or-later

<#
.SYNOPSIS
Fetch and merge a fork branch into the current branch.
.EXAMPLE
.\tools\Merge-ForkBranch.ps1 https://github.com/BlAnK182C-bak/Lichii/tree/av1-cutscene-sync
.EXAMPLE
.\tools\Merge-ForkBranch.ps1 https://github.com/ZeroOneTV/Lichii/tree/perf/oot-pipeline-stalls -Preview
.NOTES
Requires Git with merge-tree --write-tree support (Git 2.38 or newer).
Does not push, stash changes, configure Git identity, or run builds/tests.
#>
[CmdletBinding(DefaultParameterSetName = 'Url')]
param(
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Url')]
    [string]$BranchUrl,

    [Parameter(Mandatory, ParameterSetName = 'Source')]
    [string]$SourceRepository,

    [Parameter(Mandatory, ParameterSetName = 'Source')]
    [string]$Branch,

    [string]$Repository = (Split-Path -Parent $PSScriptRoot),
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Git {
    param([string[]]$GitArguments)
    $output = & git --no-pager -C $Repository @GitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArguments -join ' ') failed (exit $LASTEXITCODE)."
    }
    return $output
}

if ($PSCmdlet.ParameterSetName -eq 'Url') {
    if ($BranchUrl -notmatch '^https://github\.com/([^/]+)/([^/]+)/tree/([^?#]+?)/?$') {
        throw 'Expected https://github.com/<owner>/<repository>/tree/<branch>.'
    }
    $SourceRepository = "https://github.com/$($Matches[1])/$($Matches[2]).git"
    $Branch = [Uri]::UnescapeDataString($Matches[3])
}
if ($SourceRepository.StartsWith('-') -or $Branch.StartsWith('-')) {
    throw 'Repository and branch must not start with a dash.'
}
Invoke-Git @('check-ref-format', '--branch', $Branch) | Out-Null
$currentBranch = Invoke-Git @('symbolic-ref', '--quiet', '--short', 'HEAD')
$originalHead = Invoke-Git @('rev-parse', 'HEAD')
foreach ($state in @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply')) {
    $statePath = Invoke-Git @('rev-parse', '--path-format=absolute', '--git-path', $state)
    if (Test-Path -LiteralPath $statePath) {
        throw "Finish or abort the existing Git operation ($state) before running this script."
    }
}
if (Invoke-Git @('status', '--porcelain', '--untracked-files=all')) {
    throw 'Working tree is not clean. Commit or stash your changes yourself before merging.'
}

Invoke-Git @('fetch', '--no-tags', $SourceRepository, $Branch)
$incoming = Invoke-Git @('rev-parse', 'FETCH_HEAD')
& git --no-pager -C $Repository merge-base --is-ancestor $incoming HEAD
$ancestorExit = $LASTEXITCODE
if ($ancestorExit -eq 0) {
    Write-Host "Already merged: $SourceRepository branch $Branch ($incoming)."
    return
}
if ($ancestorExit -ne 1) {
    throw "Could not check branch ancestry (exit $ancestorExit)."
}

Write-Host "Incoming commits for ${currentBranch}:"
Invoke-Git @('log', '--oneline', "HEAD..$incoming")
Invoke-Git @('diff', '--stat', "HEAD...$incoming")
$mergeTree = @(Invoke-Git @('merge-tree', '--write-tree', '--name-only', 'HEAD', $incoming))
$expectedTree = $mergeTree[0]
if ($Preview) {
    Write-Host "Clean merge preview: $incoming into $currentBranch. No merge performed."
    return
}

Invoke-Git @('var', 'GIT_AUTHOR_IDENT') | Out-Null
Invoke-Git @('var', 'GIT_COMMITTER_IDENT') | Out-Null
if ((Invoke-Git @('rev-parse', 'HEAD')) -ne $originalHead -or
    (Invoke-Git @('symbolic-ref', '--quiet', '--short', 'HEAD')) -ne $currentBranch -or
    (Invoke-Git @('status', '--porcelain', '--untracked-files=all'))) {
    throw 'Repository changed during preparation. Run the script again.'
}
Invoke-Git @(
    'merge', '--no-ff', '--no-edit', $incoming,
    '-m', "Merge $SourceRepository branch $Branch into $currentBranch",
    '-m', 'Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>'
)
$actualTree = Invoke-Git @('rev-parse', 'HEAD^{tree}')
if ($actualTree -ne $expectedTree) {
    throw 'Merge completed, but its tree differs from the preview. Inspect the result before pushing.'
}
Invoke-Git @('merge-base', '--is-ancestor', $incoming, 'HEAD')
if (Invoke-Git @('status', '--porcelain', '--untracked-files=all')) {
    throw 'Merge completed, but the working tree is no longer clean. Inspect before pushing.'
}
Invoke-Git @('log', '-1', '--format=%h %p %s')
Write-Host 'Merge verified. Not pushed; builds/tests were not run.'
