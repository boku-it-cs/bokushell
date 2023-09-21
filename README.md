
<img src="https://img.shields.io/badge/powershell-5391FE?style=for-the-badge&logo=powershell&logoColor=white" /> <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" /> <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" /> <img src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" /> <img src="https://img.shields.io/badge/Visual_Studio_Code-0078D4?style=for-the-badge&logo=visual%20studio%20code&logoColor=white" />

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# BOKUshell

A powerful PowerShell module to interact with BOKU systems.

## Import

```powershell
PS> Import-Module <BOKUshell path>\BOKUshell.psd1
PS> Get-Module BOKUshell

ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     0.0.1      BOKUshell                           {Get-BOKUGroupMember}
```

## Commands

### Get-BOKUGroupMembers

Get BOKU group members

```powershell
Get-BOKUGroupMember -GroupNames Groupname1,Groupname2
```

## Licensing

This project is licensed under the MIT License.
See [LICENSE](https://github.com/boku-it-cs/bokushell/blob/master/LICENSE).
