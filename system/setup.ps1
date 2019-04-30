$setupCode = {
    $rootPresentationPath = Get-PSFConfigValue -FullName PSDemo.Path.PresentationsRoot -Fallback "F:\Code\Github"
    $tempPath = Get-PSFConfigValue -FullName psutil.path.temp -Fallback $env:TEMP

    $null = New-Item -Path $tempPath -Name demo -Force -ErrorAction Ignore -ItemType Directory
    $null = New-PSDrive -Name demo -PSProvider FileSystem -Root $tempPath\demo -ErrorAction Ignore
    Set-Location demo:
    Get-ChildItem -Path demo:\ -ErrorAction Ignore | Remove-Item -Force -Recurse

    $filesRoot = Join-Path $rootPresentationPath "Presentations\Logging in a DevOps world\powershell"
    
    Add-Type -Path (Join-Path (Get-Module dbatools -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase "bin\dbatools.dll")
    function prompt {
        $string = ""
        try
        {
            $history = Get-History -ErrorAction Ignore
            if ($history)
            {
                $insert = ([Sqlcollaborative.Dbatools.Utility.DbaTimeSpanPretty]($history[-1].EndExecutionTime - $history[-1].StartExecutionTime)).ToString().Replace(" s", " s ")
                $padding = ""
                if ($insert.Length -lt 9) { $padding = " " * (9 - $insert.Length) }
                $string = "$padding[<c='red'>$insert</c>] "
            }
        }
        catch { }
        Write-PSFHostColor -String "$($string)Demo:" -NoNewLine
        
        "> "
    }
    Import-Module PSUtil

    Import-PSFLocalizedString -Path "$filesRoot\strings_de.psd1" -Module Litter -Language de-DE
    Import-PSFLocalizedString -Path "$filesRoot\strings_en.psd1" -Module Litter -Language en-US
}
. $setupCode
Set-Content -Value $setupCode -Path $profile.CurrentUserCurrentHost