param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSCommandPath
$core = Join-Path $scriptDir 'project-ops.ps1'

function Invoke-Core {
  param([string[]]$PassArgs)
  & powershell -ExecutionPolicy Bypass -File $core @PassArgs
}

if (-not $Args -or $Args.Count -eq 0) {
  Invoke-Core @('-Action','menu')
  exit $LASTEXITCODE
}

$cmd = $Args[0]

# /project N
if ($cmd -match '^[0-9]+$') {
  Invoke-Core @('-Action','choose','-Pick',$cmd)
  exit $LASTEXITCODE
}

switch ($cmd.ToLower()) {
  'list' {
    Invoke-Core @('-Action','list')
  }
  'menu' {
    Invoke-Core @('-Action','menu')
  }
  'choose' {
    if ($Args.Count -lt 2) { throw 'Usage: /project choose <N|project-id>' }
    $target = $Args[1]
    if ($target -match '^[0-9]+$') {
      Invoke-Core @('-Action','choose','-Pick',$target)
    } else {
      Invoke-Core @('-Action','choose','-Id',$target)
    }
  }
  'push' {
    if ($Args.Count -lt 2) { throw 'Usage: /project push <project-id> [note]' }
    $id = $Args[1]
    $note = if ($Args.Count -ge 3) { ($Args[2..($Args.Count-1)] -join ' ') } else { 'Manual push kickoff via /project push' }
    Invoke-Core @('-Action','kickoff','-Id',$id,'-Note',$note,'-Agent','agent:mika','-Title','manual-push')
  }
  'log' {
    if ($Args.Count -lt 3) { throw 'Usage: /project log <project-id> <note>' }
    $id = $Args[1]
    $note = ($Args[2..($Args.Count-1)] -join ' ')
    Invoke-Core @('-Action','log','-Id',$id,'-Agent','agent:mika','-Title','manual-log','-Note',$note)
  }
  'archive' {
    if ($Args.Count -lt 2) { throw 'Usage: /project archive <project-id> [note]' }
    $id = $Args[1]
    $note = if ($Args.Count -ge 3) { ($Args[2..($Args.Count-1)] -join ' ') } else { 'Archived via /project archive' }
    Invoke-Core @('-Action','archive','-Id',$id,'-Note',$note)
  }
  'status' {
    if ($Args.Count -lt 2) { throw 'Usage: /project status <project-id>' }
    Invoke-Core @('-Action','status','-Id',$Args[1])
  }
  'suggest' {
    Invoke-Core @('-Action','suggest')
  }
  'today' {
    Invoke-Core @('-Action','suggest')
  }
  default {
    throw "Unknown /project subcommand: $cmd"
  }
}
