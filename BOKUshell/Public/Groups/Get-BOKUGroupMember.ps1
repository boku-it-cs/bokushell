<#
.SYNOPSIS
   Get BOKU group members
.DESCRIPTION
   Lange Beschreibung
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Format Json -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Format Csv -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Format Table -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Format Csv -ExportPath $env:TEMP -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -GroupCategories GroupCategory1,GroupCategory2 -Format Json -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Usernames Username1 -GroupCategories GroupCategory1,GroupCategory2 -Format Json -Verbose
.EXAMPLE
   .\Get-BOKUGroupMember.ps1 -GroupNames Groupname1,Groupname2 -Format Json -ResolveUsernames -Verbose
.INPUTS
    Eingaben
.OUTPUTS
    Ausgaben
.NOTES
    FunctionName    : Get-BOKUGroupMembers
    AuthorName      : Andreas Wegscheider
    Version         : 0.1.0
    More info       : https://confluence.boku.ac.at/x/1In0C
.LINK
    Find more informations at our confluence space:
    https://confluence.boku.ac.at/x/1In0C
#>

<#
0.0.1 - Initial script - GroupNames only
0.0.2 - Formatting Json, Csv, Table
0.0.3 - ExportPath
0.0.4 - GroupCategories
0.0.5 - Filter members via Usernames - BETA
0.0.6 - make use of wildcards in groupnames
0.1.0 - Resolve Usernames into Displaynames
#>


#region Params
[CmdletBinding(DefaultParameterSetName = 'BOKUDefaultParameterSetName')]
param(
    [Parameter(Mandatory = $False,
        HelpMessage = "Gruppenname(n), nach dem/denen gesucht werden soll. Default Categories: permissions,funktionen,synced.")]
    [string[]]$GroupNames,
    [Parameter(Mandatory = $False,
        HelpMessage = "Username(n), nach dem/denen gefiltert werden soll.")]
    [string[]]$Usernames,
    [Parameter(Mandatory = $False,
        HelpMessage = "Kategorien. As default it searches in permissions,funktionen and synced.")]
    [ValidateSet("permissions", "funktionen", "synced", "edvlap", "extra", "maphelper", "webcontent")]
    [string[]]$GroupCategories,
    [Parameter(Mandatory = $False,
        HelpMessage = "Exportpfad.")]
    [string]$ExportPath,
    [Parameter(Mandatory = $False,
        HelpMessage = "Ausgabeformat. Default=JSON.")]
    [ValidateSet("Json", "Table", "Csv")]
    [string]$Format = "Json",
    [Parameter(Mandatory = $False,
        HelpMessage = ". Default=False.")]
    [bool]$MakeUseOfWildcards = $False,
    [Parameter(Mandatory = $False,
        HelpMessage = ". Default=False.")]
    [switch]$ResolveIntoDisplayNames
)
#endregion


#region Functions

#region function GetGroupProperties
function GetGroupProperties($strGroupName, $strGroupCategories) {
    Write-Debug "Count Groupname: $strGroupname"

    foreach ($strGroupCategory in $strGroupCategories) {
        Write-Debug "Category: $strGroupCategory"

        $GroupMemberCount = \\serversoft\datasoft\tools\grplist.exe $theJoption $theMoption $theToption $theYoption "${strGroupname}.${strGroupCategory}.groups"

        foreach ($Line in $GroupMemberCount) {
            if (!$Line) { Continue }
            if ($Line.StartsWith('GRPLIST: No groups found matching ' + $strGroupname)) { Continue }

            $result = $Line.Split(',')

            Write-Debug $Line
            Write-Debug $result[1]
            Write-Debug $strGroupCategory

            return $strGroupCategory, $result[1]
        }
    }
    return $false
}
#endregion function GetGroupProperties

#region function GetGroupMembers
function GetGroupMembers($strGroupName, $strGroupCategory) {
    Write-Debug "Members Groupname: $strGroupName"
    Write-Debug "Members Groupcategory: $strGroupCategory"
    $Members = New-Object System.Collections.ArrayList

    Write-Debug "\\serversoft\datasoft\tools\grplist.exe ${theAoption} ${theDoption} ${theJoption} ${theMoption} ${theNoption} ${theSoption} ${theYoption} '${strGroupname}.${strGroupCategory}.groups'"
    $GroupMembers = \\serversoft\datasoft\tools\grplist.exe $theAoption $theDoption $theJoption $theMoption $theNoption $theSoption $theYoption "${strGroupName}.${strGroupCategory}.groups"

    foreach ($Line in $GroupMembers) {
        if (!$Line) { Continue }
        if ($Line.StartsWith('GRPLIST: No groups found matching ' + $strGroupName)) { Continue }

        $result = $Line.Split(',')
        $Members.Add($result[1]) | Out-Null
    }

    if ($Members) { return $Members }

    return $null
}
#endregion function GetGroupMembers

#endregion Functions



If ( $PSBoundParameters.Debug.IsPresent ) { $DebugPreference = "Continue"; }
If ( $GroupNames -like "`*" ) { $MakeUseOfWildcards = $True; }

#write-host $GroupNames
#echo $MakeUseOfWildcards
#exit


$theAoption = '/a' # only unique for nested groups
$theDoption = '/d' # display aliases
$theJoption = '/j' # suppress output of headings and totals
$theMoption = '/m' # groupname AND member per line; comma separated
$theNoption = '/n' # suppress full names
$theSoption = '/s=o' # sort by o = object name, r = reverse
$theToption = '/t' #  only total members
$theYoption = '/y=s' # output display c = canonical; s = short; l = ldap; t = types included; u = replace spaces with undersocres

if ( !$GroupCategories ) { $GroupCategories = "permissions", "funktionen", "synced"; }

$g = [ordered]@{groups = @() }
if ( $Format -eq "Csv" -and !$ResolveIntoDisplayNames ) { $Csv = "Date;Time;GroupName;MemberName;GroupCategory;GroupSize;FullGroupName;FullMemberName`r`n"; }
if ( $Format -eq "Csv" -and $ResolveIntoDisplayNames ) { $Csv = "Date;Time;GroupName;DisplayName;GroupCategory;GroupSize;FullGroupName;FullMemberName`r`n"; }

if ( $Usernames ) { $UsernamesInTheGroups = $False; }



# Start
$StartDate = Get-Date
$Filename = (Get-Date).Ticks
Write-Verbose "Beginn: $StartDate"

If ( $null -ne $GroupNames ) {
    foreach ($GroupName in $GroupNames) {
        $groupscount++

        $result = GetGroupProperties $GroupName $GroupCategories
        $thisGC = $result[0]
        $thisGS = $result[1]
        
        $Datum = (Get-Date -Format "dd.MM.yyyy")

        if ( $Format -eq "Json" ) {
            $thisGMs = New-Object System.Collections.ArrayList
            if ($thisGC) {
                $Members = GetGroupMembers $GroupName $thisGC
                foreach ($Member in $Members) {
                    $groupmemberscount++
                    if ( $Usernames ) {
                        foreach ( $Username in $Usernames ) {
                            if ( $Username -ne $Member ) { Continue }
                            if ( !$ResolveIntoDisplayNames ) {
                                $thisGMs.Add($Member) | Out-Null
                            }
                            else {
                                $DisplayName = .\Get-BOKUUserInformation.ps1 -Usernames $Member
                                $thisGMs.Add(@{$Member = $DisplayName }) | Out-Null
                            }
                            
                            $UsernamesInTheGroups = $True;
                        }
                    }
                    else {
                        if ( !$ResolveIntoDisplayNames ) {
                            $thisGMs.Add($Member) | Out-Null
                        }
                        else {
                            $DisplayName = .\Get-BOKUUserInformation.ps1 -Usernames $Member
                            $thisGMs.Add(@{$Member = $DisplayName }) | Out-Null
                        }
                    }
                }
            }
            #Write-Debug $thisGMs
            
            $Zeit = (Get-Date -Format "HH:mm:ss")
        
            $groupObject = New-Object PSObject
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "Date" -Value $Datum
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "Time" -Value $Zeit
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "GroupName" -Value $GroupName
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "Members" -Value $thisGMs
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "GroupCategory" -Value $thisGC
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "GroupSize" -Value $thisGS
            Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "FullGroupName" -Value "${GroupName}.${thisGC}.groups"
            if ( $Usernames ) {
                Add-Member -InputObject $groupObject -MemberType NoteProperty -Name "UsernameFoundInGroup" -Value $UsernamesInTheGroups
            }
            Write-Debug $groupObject
        
            $g.groups += $groupObject
        }
        elseif ( $Format -eq "Csv" ) {
            $Members = GetGroupMembers $GroupName $thisGC
            foreach ($Member in $Members) {
                $groupmemberscount++
                $Zeit = (Get-Date -Format "HH:mm:ss")
                if ( $Usernames ) {
                    foreach ( $Username in $Usernames ) {
                        if ( $Username -ne $Member ) { Continue }
                        if ( !$ResolveIntoDisplayNames ) {
                            $Csv += "${Datum};${Zeit};${GroupName};${Member};${thisGC};${thisGS};${GroupName}.${thisGC}.groups.boku;${Member}.users.boku`r`n"
                        }
                        else {
                            $DisplayName = .\Get-BOKUUserInformation.ps1 -Usernames $Member
                            $Csv += "${Datum};${Zeit};${GroupName};${DisplayName};${thisGC};${thisGS};${GroupName}.${thisGC}.groups.boku;${Member}.users.boku`r`n"
                        }
                        $UsernamesInTheGroups = $True;
                    }
                }
                else {
                    if ( !$ResolveIntoDisplayNames ) {
                        $Csv += "${Datum};${Zeit};${GroupName};${Member};${thisGC};${thisGS};${GroupName}.${thisGC}.groups.boku;${Member}.users.boku`r`n"
                    }
                    else {
                        $DisplayName = .\Get-BOKUUserInformation.ps1 -Usernames $Member
                        $Csv += "${Datum};${Zeit};${GroupName};${DisplayName};${thisGC};${thisGS};${GroupName}.${thisGC}.groups.boku;${Member}.users.boku`r`n"
                    }
                }
            }
        }
    }
}


# End
$EndDate = Get-Date
Write-Verbose "Ende: $EndDate"

$Duration = New-TimeSpan -Start $StartDate -End $EndDate



# Output

# JSON
If ( $Format -eq "Json" ) {
    $Json = ( ConvertTo-Json $g -Depth 5 | Get-Unique )
    if ( $groupmemberscount ) {
        $Json

        If ( $ExportPath ) { $jsonfile = "$($ExportPath)\$($Filename).json"; $Json | Out-File $jsonfile; Write-Verbose $jsonfile; Write-Host "Export-File: $($jsonfile)"; Invoke-Item $jsonfile; }
    }
    else {
        Write-Output "{}"
    }
}
# Csv
If ( $Format -eq "Csv" ) {
    if ( $groupmemberscount ) {
        $Csv.Trim("`r`n")

        If ( $ExportPath ) { $csvfile = "$($ExportPath)\$($Filename).csv"; $Csv | Out-File $csvfile; Write-Verbose $csvfile; Write-Host "Export-File: $($csvfile)"; Invoke-Item $csvfile; }
    }
    else {
        Write-Output "{}"
    }
}


Write-Debug "GroupsCount= $($groupscount)"
Write-Debug "GroupMembersCount= $($groupmemberscount)"
if ( $Usernames ) {
    Write-Verbose "UsernamesInTheGroups: $UsernamesInTheGroups"
}
Write-Verbose "GroupMembers search lasted $($Duration.TotalSeconds) s"