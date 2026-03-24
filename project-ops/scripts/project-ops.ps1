param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('init','list','menu','choose','status','continue','update','log','assign','kickoff','archive','suggest')]
  [string]$Action,

  [string]$Id,
  [int]$Pick,
  [string]$Name,
  [string]$Type = 'product',
  [string]$Owner = 'unassigned',
  [string]$Status,
  [int]$Progress,
  [string]$RepoPath,
  [string]$WorkflowPath,
  [string]$Goal,
  [string]$Next,
  [string]$Note,
  [string]$Agent,
  [string]$Role,
  [string]$Title
)

$ErrorActionPreference = 'Stop'

function Get-Now {
  (Get-Date).ToString("yyyy-MM-dd HH:mm:ss 'GMT+8'")
}

function Get-WorkspaceRoot {
  $scriptPath = $PSCommandPath
  if (-not $scriptPath) { throw "Cannot resolve script path" }
  $scriptDir = Split-Path -Parent $scriptPath
  $skillDir = Split-Path -Parent $scriptDir
  $skillsDir = Split-Path -Parent $skillDir
  Split-Path -Parent $skillsDir
}

$WorkspaceRoot = Get-WorkspaceRoot
$ProjectsRoot = Join-Path $WorkspaceRoot '.projects'
$IndexPath = Join-Path $ProjectsRoot 'index.json'

function Ensure-Root {
  if (-not (Test-Path $ProjectsRoot)) {
    New-Item -ItemType Directory -Path $ProjectsRoot -Force | Out-Null
  }
  if (-not (Test-Path $IndexPath)) {
    $seed = [ordered]@{
      version = '1.3'
      updatedAt = Get-Now
      projects = @()
    }
    $seed | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $IndexPath -Encoding UTF8
  }
}

function Load-Index {
  Ensure-Root
  $obj = Get-Content -LiteralPath $IndexPath -Raw | ConvertFrom-Json
  if ($null -eq $obj.projects) { $obj | Add-Member -NotePropertyName projects -NotePropertyValue @() }
  return $obj
}

function Save-Index($idx) {
  $idx.updatedAt = Get-Now
  $idx.version = '1.3'
  $idx | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $IndexPath -Encoding UTF8
}

function Get-ProjectDir([string]$projectId) {
  Join-Path $ProjectsRoot $projectId
}

function Get-ProjectJsonPath([string]$projectId) {
  Join-Path (Get-ProjectDir $projectId) 'project.json'
}

function Load-Project([string]$projectId) {
  $p = Get-ProjectJsonPath $projectId
  if (-not (Test-Path $p)) { throw "Project not found: $projectId" }
  Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
}

function Save-Project($project) {
  $p = Get-ProjectJsonPath $project.id
  $project.updatedAt = Get-Now
  $project | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $p -Encoding UTF8
}

function Upsert-IndexEntry($idx, $project) {
  $exists = $idx.projects | Where-Object { $_.id -eq $project.id } | Select-Object -First 1
  if ($null -eq $exists) {
    $idx.projects += [pscustomobject]@{
      id = $project.id
      name = $project.name
      status = $project.status
      progress = [int]$project.progress
      owner = $project.owner
      type = $project.type
      updatedAt = $project.updatedAt
      path = ".projects/$($project.id)/project.json"
    }
  } else {
    $exists.name = $project.name
    $exists.status = $project.status
    $exists.progress = [int]$project.progress
    $exists.owner = $project.owner
    $exists.type = $project.type
    $exists.updatedAt = $project.updatedAt
    $exists.path = ".projects/$($project.id)/project.json"
  }
}

function Ensure-History($project) {
  if ($null -eq $project.history) {
    $project | Add-Member -NotePropertyName history -NotePropertyValue @()
  }
}

function Ensure-AgentAssignments($project) {
  if ($null -eq $project.agentAssignments) {
    $project | Add-Member -NotePropertyName agentAssignments -NotePropertyValue @()
  }
}

function Get-StatusWeight([string]$status) {
  switch ($status) {
    'active' { return 0 }
    'blocked' { return 1 }
    'on_hold' { return 2 }
    'done' { return 3 }
    'archived' { return 4 }
    default { return 9 }
  }
}

function Get-StatusPriority([string]$status) {
  switch ($status) {
    'blocked' { return 100 }
    'active' { return 70 }
    'on_hold' { return 40 }
    'done' { return 5 }
    'archived' { return 0 }
    default { return 10 }
  }
}

function Get-SortedProjects($idx) {
  $idx.projects | Sort-Object @{Expression={Get-StatusWeight $_.status};Ascending=$true}, @{Expression='updatedAt';Descending=$true}
}

function Emit-ContinueSnapshot($project) {
  @(
    "PROJECT: $($project.name) ($($project.id))"
    "STATUS: $($project.status)"
    "PROGRESS: $($project.progress)%"
    "OWNER: $($project.owner)"
    "TYPE: $($project.type)"
    "REPO: $($project.repoPath)"
    "WORKFLOW: $($project.workflowPath)"
    "GOAL: $($project.currentGoal)"
    "NEXT: $($project.nextAction)"
    "LAST_NOTE: $($project.lastNote)"
    "UPDATED: $($project.updatedAt)"
  )
}

function Get-GitSignals([string]$repoPath) {
  $ret = [ordered]@{
    validRepo = $false
    branch = ''
    ahead = 0
    behind = 0
    staged = 0
    modified = 0
    untracked = 0
    unmerged = 0
    rawSummary = ''
    error = ''
  }

  if (-not $repoPath -or -not (Test-Path $repoPath)) {
    $ret.error = 'repoPath missing or not found'
    return [pscustomobject]$ret
  }

  $lines = @(& git -C $repoPath status --porcelain -b 2>$null)
  if ($LASTEXITCODE -ne 0 -or $lines.Count -eq 0) {
    $ret.error = 'git status unavailable'
    return [pscustomobject]$ret
  }

  $ret.validRepo = $true
  $branchLine = $lines[0]
  if ($branchLine.StartsWith('## ')) {
    $ret.branch = $branchLine.Substring(3)
    if ($branchLine -match 'ahead ([0-9]+)') { $ret.ahead = [int]$Matches[1] }
    if ($branchLine -match 'behind ([0-9]+)') { $ret.behind = [int]$Matches[1] }
  }

  for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 2) { continue }

    $xy = $line.Substring(0,2)
    $x = $xy[0]
    $y = $xy[1]

    if ($xy -eq '??') {
      $ret.untracked++
      continue
    }

    if ($x -eq 'U' -or $y -eq 'U' -or $xy -in @('AA','DD','AU','UA','DU','UD')) {
      $ret.unmerged++
      continue
    }

    if ($x -ne ' ' -and $x -ne '?') { $ret.staged++ }
    if ($y -ne ' ') { $ret.modified++ }
  }

  $ret.rawSummary = "branch=$($ret.branch); staged=$($ret.staged); modified=$($ret.modified); untracked=$($ret.untracked); unmerged=$($ret.unmerged); ahead=$($ret.ahead); behind=$($ret.behind)"
  return [pscustomobject]$ret
}

function Append-ProjectLog([string]$projectId, [string]$agentName, [string]$logTitle, [string]$noteText, [switch]$KickoffTemplate) {
  $project = Load-Project $projectId
  $logDir = Join-Path (Get-ProjectDir $projectId) 'logs'
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null

  $date = (Get-Date).ToString('yyyy-MM-dd')
  $time = (Get-Date).ToString('HH:mm')
  $logFile = Join-Path $logDir "$date.md"

  if ($KickoffTemplate) {
    $entry = @(
      "### [$time] $agentName - $logTitle"
      ""
      "**Kickoff Goal**"
      "- $($project.currentGoal)"
      ""
      "**Next Action**"
      "- $($project.nextAction)"
      ""
      "**Execution Checklist**"
      "- [ ] Align repo + workflow baseline"
      "- [ ] Split task to assigned agents"
      "- [ ] Produce tangible output (code/docs/tests)"
      "- [ ] Update progress + nextAction"
      ""
      "**Note**"
      "- $noteText"
      ""
      "---"
      ""
    ) -join "`r`n"
  } else {
    $entry = @(
      "### [$time] $agentName - $logTitle"
      ""
      "- Note: $noteText"
      "- Status: $($project.status)"
      "- Progress: $($project.progress)%"
      ""
      "---"
      ""
    ) -join "`r`n"
  }

  Add-Content -LiteralPath $logFile -Value $entry -Encoding UTF8
}

function Ensure-ProjectDocScaffold([string]$projectId, [string]$projectName) {
  $dir = Get-ProjectDir $projectId
  $masterPlan = Join-Path $dir 'MASTER_PLAN.md'
  $nextPlan = Join-Path $dir 'NEXT_SESSION_PLAN.md'

  if (-not (Test-Path $masterPlan)) {
    $masterText = @(
      "# MASTER_PLAN.md — $projectName"
      ""
      "Project ID: $projectId"
      "Owner: unassigned"
      "Mode: session-driven execution (one micro-goal per session)"
      ""
      "## 0) Locked Product Decisions"
      "- (to be filled)"
      ""
      "## 1) Milestones and Session Backlog"
      "- M0: ..."
      ""
      "## 2) Session Execution Contract"
      "1. target session id"
      "2. done/not-done checklist"
      "3. code/file changes"
      "4. test evidence"
      "5. progress delta"
      "6. next actionable id"
    ) -join "`r`n"
    $masterText | Set-Content -LiteralPath $masterPlan -Encoding UTF8
  }

  if (-not (Test-Path $nextPlan)) {
    $nextText = @(
      "# NEXT_SESSION_PLAN.md"
      ""
      "Project: $projectId"
      "Current Session Target: S00"
      ""
      "## Context Lock"
      "- (to be filled)"
      ""
      "## Task Packet"
      "- (to be filled)"
      ""
      "## Acceptance Checklist"
      "- [ ] target done"
      "- [ ] no regression"
      "- [ ] trackers updated"
    ) -join "`r`n"
    $nextText | Set-Content -LiteralPath $nextPlan -Encoding UTF8
  }
}

switch ($Action) {
  'init' {
    if (-not $Id -or -not $Name) { throw 'init requires -Id and -Name' }

    $idx = Load-Index
    if ($idx.projects | Where-Object { $_.id -eq $Id }) {
      throw "Project already exists: $Id"
    }

    $dir = Get-ProjectDir $Id
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'logs') -Force | Out-Null

    $defaultWorkflow = Join-Path $dir 'MASTER_PLAN.md'
    $now = Get-Now
    $project = [ordered]@{
      id = $Id
      name = $Name
      status = 'active'
      progress = 0
      owner = $Owner
      type = $Type
      repoPath = $(if($PSBoundParameters.ContainsKey('RepoPath')){$RepoPath}else{''})
      workflowPath = $(if($PSBoundParameters.ContainsKey('WorkflowPath')){$WorkflowPath}else{$defaultWorkflow})
      currentGoal = ''
      nextAction = 'Define first actionable task'
      lastNote = 'Initialized project'
      agentAssignments = @()
      milestones = @()
      history = @(
        [ordered]@{ time = $now; action = 'init'; note = 'Project initialized' }
      )
      createdAt = $now
      updatedAt = $now
    }

    $project | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Get-ProjectJsonPath $Id) -Encoding UTF8
    Upsert-IndexEntry $idx $project
    Save-Index $idx
    Ensure-ProjectDocScaffold -projectId $Id -projectName $Name

    Write-Output "OK:init:${Id}"
    break
  }

  'list' {
    $idx = Load-Index
    if ($idx.projects.Count -eq 0) {
      Write-Output 'No projects found.'
      break
    }

    Get-SortedProjects $idx | ForEach-Object {
      "[$($_.status)] $($_.id) | $($_.name) | progress=$($_.progress)% | owner=$($_.owner) | updated=$($_.updatedAt)"
    }
    break
  }

  'menu' {
    $idx = Load-Index
    if ($idx.projects.Count -eq 0) {
      Write-Output 'No projects found.'
      break
    }

    $sorted = @(Get-SortedProjects $idx)
    Write-Output '=== PROJECT MENU ==='
    for ($i = 0; $i -lt $sorted.Count; $i++) {
      $p = $sorted[$i]
      Write-Output ("{0}) [{1}] {2} | {3} | {4}% | next: {5}" -f ($i+1), $p.status, $p.id, $p.name, $p.progress, ((Load-Project $p.id).nextAction))
    }
    Write-Output 'Tip: use /project N or /project choose <N|id>'
    break
  }

  'choose' {
    $idx = Load-Index
    if ($PSBoundParameters.ContainsKey('Id') -and $Id) {
      $project = Load-Project $Id
      Emit-ContinueSnapshot $project
      break
    }

    if (-not $PSBoundParameters.ContainsKey('Pick')) {
      throw 'choose requires -Pick <number> or -Id <project-id>'
    }

    $sorted = @(Get-SortedProjects $idx)
    if ($Pick -lt 1 -or $Pick -gt $sorted.Count) {
      throw "pick out of range: $Pick"
    }

    $chosen = $sorted[$Pick - 1]
    $project = Load-Project $chosen.id
    Emit-ContinueSnapshot $project
    break
  }

  'status' {
    if (-not $Id) { throw 'status requires -Id' }
    $project = Load-Project $Id
    $project | ConvertTo-Json -Depth 30
    break
  }

  'continue' {
    if (-not $Id) { throw 'continue requires -Id' }
    $project = Load-Project $Id
    Emit-ContinueSnapshot $project
    break
  }

  'suggest' {
    $idx = Load-Index
    if ($idx.projects.Count -eq 0) {
      Write-Output 'No projects found.'
      break
    }

    $items = @()
    foreach ($entry in (Get-SortedProjects $idx)) {
      $project = Load-Project $entry.id
      if ($project.status -in @('archived','done')) { continue }

      $score = Get-StatusPriority $project.status
      $reasons = @()
      $git = Get-GitSignals $project.repoPath

      if (-not $git.validRepo) {
        $score += 15
        $reasons += 'repo unavailable'
      } else {
        if ($git.unmerged -gt 0) {
          $score += 50
          $reasons += "merge-conflicts:$($git.unmerged)"
        }
        if ($git.behind -gt 0) {
          $score += 20
          $reasons += "behind:$($git.behind)"
        }
        if (($git.staged + $git.modified) -gt 0) {
          $score += 10
          $reasons += "dirty:$($git.staged + $git.modified)"
        }
        if ($git.untracked -gt 20) {
          $score += 5
          $reasons += "many-untracked:$($git.untracked)"
        }
      }

      if (-not $project.nextAction -or [string]::IsNullOrWhiteSpace($project.nextAction)) {
        $score += 10
        $reasons += 'nextAction-missing'
      }

      $suggestion = ''
      if ($git.validRepo -and $git.unmerged -gt 0) {
        $suggestion = 'Resolve merge conflicts first, then continue feature work.'
      } elseif ($git.validRepo -and $git.behind -gt 0) {
        $suggestion = 'Sync remote first (git pull --rebase) to avoid downstream conflicts.'
      } elseif ($git.validRepo -and ($git.staged + $git.modified) -gt 0) {
        $suggestion = 'Clean workspace first (commit/branch hygiene), then execute nextAction.'
      } elseif ($project.nextAction -and -not [string]::IsNullOrWhiteSpace($project.nextAction)) {
        $suggestion = $project.nextAction
      } else {
        $suggestion = 'Define the next executable task and write it into nextAction.'
      }

      $items += [pscustomobject]@{
        id = $project.id
        name = $project.name
        status = $project.status
        progress = $project.progress
        score = $score
        reasons = ($(if($reasons.Count -gt 0){$reasons -join ', '}else{'baseline'}))
        suggestion = $suggestion
        git = $(if($git.validRepo){$git.rawSummary}else{'git-unavailable'})
      }
    }

    if ($items.Count -eq 0) {
      Write-Output 'No active/blocked projects for suggestion.'
      break
    }

    $sortedItems = $items | Sort-Object @{Expression='score';Descending=$true}, @{Expression='progress';Descending=$false}
    Write-Output "=== TODAY PUSH SUGGESTIONS ($(Get-Now)) ==="
    $rank = 1
    foreach ($it in $sortedItems) {
      Write-Output ("{0}) P{1} [{2}] {3} | {4}%" -f $rank, $it.score, $it.status, $it.id, $it.progress)
      Write-Output ("   reason: {0}" -f $it.reasons)
      Write-Output ("   git: {0}" -f $it.git)
      Write-Output ("   do: {0}" -f $it.suggestion)
      $rank++
    }
    break
  }

  'update' {
    if (-not $Id) { throw 'update requires -Id' }
    $idx = Load-Index
    $project = Load-Project $Id
    Ensure-History $project

    if ($PSBoundParameters.ContainsKey('Status')) { $project.status = $Status }
    if ($PSBoundParameters.ContainsKey('Progress')) { $project.progress = [Math]::Max(0,[Math]::Min(100,$Progress)) }
    if ($PSBoundParameters.ContainsKey('Goal')) { $project.currentGoal = $Goal }
    if ($PSBoundParameters.ContainsKey('Next')) { $project.nextAction = $Next }
    if ($PSBoundParameters.ContainsKey('Note')) { $project.lastNote = $Note }
    if ($PSBoundParameters.ContainsKey('RepoPath')) { $project.repoPath = $RepoPath }
    if ($PSBoundParameters.ContainsKey('WorkflowPath')) { $project.workflowPath = $WorkflowPath }

    $project.history += [pscustomobject]@{
      time = Get-Now
      action = 'update'
      note = $(if($PSBoundParameters.ContainsKey('Note')){$Note}else{'metadata update'})
      status = $project.status
      progress = $project.progress
    }

    Save-Project $project
    Upsert-IndexEntry $idx $project
    Save-Index $idx

    Write-Output "OK:update:${Id}"
    break
  }

  'assign' {
    if (-not $Id -or -not $Agent) { throw 'assign requires -Id and -Agent' }
    $idx = Load-Index
    $project = Load-Project $Id
    Ensure-History $project
    Ensure-AgentAssignments $project

    $current = $project.agentAssignments | Where-Object { $_.agent -eq $Agent } | Select-Object -First 1
    if ($null -eq $current) {
      $project.agentAssignments += [pscustomobject]@{
        agent = $Agent
        role = $(if($PSBoundParameters.ContainsKey('Role')){$Role}else{'contributor'})
        updatedAt = Get-Now
      }
    } else {
      if ($PSBoundParameters.ContainsKey('Role')) { $current.role = $Role }
      $current.updatedAt = Get-Now
    }

    $project.history += [pscustomobject]@{
      time = Get-Now
      action = 'assign'
      note = "$Agent => $(if($PSBoundParameters.ContainsKey('Role')){$Role}else{'contributor'})"
    }

    Save-Project $project
    Upsert-IndexEntry $idx $project
    Save-Index $idx

    Write-Output "OK:assign:${Id}:${Agent}"
    break
  }

  'kickoff' {
    if (-not $Id) { throw 'kickoff requires -Id' }
    $idx = Load-Index
    $project = Load-Project $Id
    Ensure-History $project

    $project.status = 'active'
    if ($PSBoundParameters.ContainsKey('Goal')) { $project.currentGoal = $Goal }
    if ($PSBoundParameters.ContainsKey('Next')) { $project.nextAction = $Next }
    if ($PSBoundParameters.ContainsKey('Note')) { $project.lastNote = $Note }

    $project.history += [pscustomobject]@{
      time = Get-Now
      action = 'kickoff'
      note = $(if($PSBoundParameters.ContainsKey('Goal')){$Goal}else{'kickoff cycle'})
      status = $project.status
      progress = $project.progress
    }

    Save-Project $project
    Upsert-IndexEntry $idx $project
    Save-Index $idx

    $agentName = $(if($PSBoundParameters.ContainsKey('Agent')){$Agent}else{'agent:mika'})
    $logTitle = $(if($PSBoundParameters.ContainsKey('Title')){$Title}else{'kickoff-cycle'})
    $noteText = $(if($PSBoundParameters.ContainsKey('Note')){$Note}else{'Kickoff created by project-ops'})
    Append-ProjectLog -projectId $Id -agentName $agentName -logTitle $logTitle -noteText $noteText -KickoffTemplate

    Write-Output "OK:kickoff:${Id}"
    break
  }

  'log' {
    if (-not $Id) { throw 'log requires -Id' }
    $project = Load-Project $Id
    Ensure-History $project

    $agentName = $(if($PSBoundParameters.ContainsKey('Agent')){$Agent}else{'agent:unknown'})
    $logTitle = $(if($PSBoundParameters.ContainsKey('Title')){$Title}else{'work-log'})
    $noteText = $(if($PSBoundParameters.ContainsKey('Note')){$Note}else{''})

    Append-ProjectLog -projectId $Id -agentName $agentName -logTitle $logTitle -noteText $noteText

    $project.history += [pscustomobject]@{
      time = Get-Now
      action = 'log'
      note = $logTitle
    }
    if ($PSBoundParameters.ContainsKey('Note')) { $project.lastNote = $Note }

    Save-Project $project

    Write-Output "OK:log:${Id}"
    break
  }

  'archive' {
    if (-not $Id) { throw 'archive requires -Id' }
    $idx = Load-Index
    $project = Load-Project $Id
    Ensure-History $project

    $project.status = 'archived'
    if ($PSBoundParameters.ContainsKey('Note')) { $project.lastNote = $Note }

    $summaryPath = Join-Path (Get-ProjectDir $Id) 'ARCHIVE.md'
    $agentLines = @('- (none)')
    if ($project.agentAssignments -and $project.agentAssignments.Count -gt 0) {
      $agentLines = @($project.agentAssignments | ForEach-Object { "- $($_.agent): $($_.role)" })
    }

    $archiveText = @(
      "# Archive - $($project.name)"
      ""
      "## Snapshot"
      "- ID: $($project.id)"
      "- Archived At: $(Get-Now)"
      "- Progress: $($project.progress)%"
      "- Owner: $($project.owner)"
      "- Status: $($project.status)"
      ""
      "## Why Archived"
      "- $($project.lastNote)"
      ""
      "## Resume Anchor"
      "- Next Action: $($project.nextAction)"
      "- Goal: $($project.currentGoal)"
      "- Repo: $($project.repoPath)"
      "- Workflow: $($project.workflowPath)"
      ""
      "## Agent Assignments"
      $agentLines
      ""
    ) -join "`r`n"

    $archiveText | Set-Content -LiteralPath $summaryPath -Encoding UTF8

    $project.history += [pscustomobject]@{
      time = Get-Now
      action = 'archive'
      note = $(if($PSBoundParameters.ContainsKey('Note')){$Note}else{'archived'})
    }

    Save-Project $project
    Upsert-IndexEntry $idx $project
    Save-Index $idx

    Write-Output "OK:archive:${Id}"
    break
  }
}

