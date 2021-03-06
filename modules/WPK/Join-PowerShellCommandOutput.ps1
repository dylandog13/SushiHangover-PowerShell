function Join-PowerShellCommandOutput(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$commandName,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$uiElementName,
    [string]$targetProperty, 
    [ScriptBlock]$updateScript,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Timespan]$interval = (New-TimeSpan),
    [switch]$last,
    [switch]$outString       
)
{  
   if ($updateScript) {
        $updateScript = [ScriptBlock]::Create(
        'param($this, $_)
        ' + $updateScript)
   }
   Write-Debug "$updateScript"
   $updateScriptBlock = [ScriptBlock]::Create(@"
        
        `$array = New-Object PSObject[] `$window.IsolatedScriptOutput.'$commandName'.Count        
        `$window.IsolatedScriptOutput.'$commandName'.CopyTo(`$array, 0)
        if (`$debugPreference -eq 'continue') { 
            Write-Debug (`$array | Out-String)
        }         
        $(if ($last) { '$array = $array[-1]' })
        $(if ($outString) { '$array = ($array | Out-String).Trim()' }) 
        `$targetElement = `$window 
        $(if ($uiElementName) {
            '$targetElement = $targetElement | Get-ChildControl "' + $uiElementName + '"'
        })
        $(if ($targetProperty) {
            '$targetElement."' + $targetProperty + '" = $array '            
        })
        $(if ($updateScript) {
            '& {' + $updateScript + '} -this $targetElement -_ $array'
        })
"@)
    Write-Debug "$updateScriptBlock"
    if ($interval.TotalMilliseconds) {
        Register-PowerShellCommand -scriptBlock $updateScriptBlock -run -in $interval
    } else {
        $updateScriptBlock
    }
} 