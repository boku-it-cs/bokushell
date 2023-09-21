<#
.Synopsis
   BOKU PowerShell Module - A powerful PowerShell module to interact with BOKU systems.
.DESCRIPTION
   More information on https://github.com/boku-it-cs/bokushell
.EXAMPLE
   Import-Module <BOKUshell path>\BOKUshell.psd1
 .NOTES
#>


Write-Verbose -Message "Loading module from path $($PSScriptRoot)."

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude "*.Tests.*" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude "*.Tests.*" -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
        Write-Verbose -Message "Exporting function '$($import.fullname)'."
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename