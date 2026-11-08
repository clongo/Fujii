# SPDX-License-Identifier: GPL-3.0-or-later

<#
.SYNOPSIS
Fetch and merge a fork branch into the current branch.
.DESCRIPTION
A conflicting merge remains in progress for manual resolution. Use -NoCommit to apply a clean
merge without creating its merge commit.
.EXAMPLE
.\tools\Merge-ForkBranch.ps1 https://github.com/BlAnK182C-bak/Lichii/tree/av1-cutscene-sync
.EXAMPLE
.\tools\Merge-ForkBranch.ps1 https://github.com/ZeroOneTV/Lichii/tree/perf/oot-pipeline-stalls -Preview
.EXAMPLE
.\tools\Merge-ForkBranch.ps1 https://github.com/ZeroOneTV/Lichii/tree/perf/oot-pipeline-stalls -NoCommit
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
    [switch]$Preview,
    [switch]$NoCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Git {
    param(
        [string[]]$GitArguments,
        [int[]]$AllowedExitCodes = @(0),
        [switch]$PassThru
    )
    $output = & git --no-pager -C $Repository @GitArguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -notin $AllowedExitCodes) {
        throw "git $($GitArguments -join ' ') failed (exit $exitCode)."
    }
    if ($PassThru) {
        return [pscustomobject]@{
            Output   = @($output)
            ExitCode = $exitCode
        }
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
$mergeTreeArguments = @('merge-tree', '--write-tree', '--name-only', 'HEAD', $incoming)
$mergeTree = Invoke-Git $mergeTreeArguments -AllowedExitCodes @(0, 1) -PassThru
$expectedTree = $mergeTree.Output[0]
$hasConflicts = $mergeTree.ExitCode -eq 1
if ($Preview) {
    if ($hasConflicts) {
        Write-Warning "Merge preview found conflicts for $incoming into $currentBranch. No merge performed."
        $mergeTree.Output | Select-Object -Skip 1 | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "Clean merge preview: $incoming into $currentBranch. No merge performed."
    }
    return
}

Invoke-Git @('var', 'GIT_AUTHOR_IDENT') | Out-Null
Invoke-Git @('var', 'GIT_COMMITTER_IDENT') | Out-Null
if ((Invoke-Git @('rev-parse', 'HEAD')) -ne $originalHead -or
    (Invoke-Git @('symbolic-ref', '--quiet', '--short', 'HEAD')) -ne $currentBranch -or
    (Invoke-Git @('status', '--porcelain', '--untracked-files=all'))) {
    throw 'Repository changed during preparation. Run the script again.'
}
$mergeArguments = @('merge', '--no-ff', '--no-edit')
if ($NoCommit) {
    $mergeArguments += '--no-commit'
}
$mergeArguments += @(
    $incoming,
    '-m', "Merge $SourceRepository branch $Branch into $currentBranch",
    '-m', 'Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>'
)
$mergeResult = Invoke-Git $mergeArguments -AllowedExitCodes @(0, 1) -PassThru
if ($mergeResult.ExitCode -eq 1) {
    $mergeResult.Output | ForEach-Object { Write-Host $_ }
    Write-Warning 'Merge conflicts remain unresolved. Resolve them and complete the merge before continuing.'
    Invoke-Git @('status', '--short')
    return
}
if ($NoCommit) {
    $actualTree = Invoke-Git @('write-tree')
    if ($actualTree -ne $expectedTree) {
        throw 'Merge applied without a commit, but its index tree differs from the preview. Inspect the result.'
    }
    if ((Invoke-Git @('rev-parse', 'MERGE_HEAD')) -ne $incoming) {
        throw 'Merge applied without a commit, but MERGE_HEAD differs from the preview. Inspect the result.'
    }
    Write-Host 'Merge applied without a commit. Review the changes, then commit or abort the merge.'
    Invoke-Git @('status', '--short')
    return
}
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
