################################################################################
# Copyright (C) 2020
# Adam Russell <adam[at]thecliguy[dot]co[dot]uk> 
# https://www.thecliguy.co.uk
#
# Licensed under the MIT License.
#
################################################################################
# Development Log:
#
# 0.1.0, 2020-04-29, Adam Russell
#   * First release.
#
################################################################################

Function Get-ChildItemToDepth {
    <#
    .SYNOPSIS
        Traverses a path recursively to a specified depth.
    
    .DESCRIPTION
        This function acts as a wrapper around Get-ChildItem, facilitating 
        recursive traversal of a path to a specific depth. Behind the scenes, it 
        operates differently based on the version of PowerShell:
        
          * Prior to PowerShell 5.0, Get-ChildItem had no built-in method to 
            limit recursive traversal of a path to a specific depth. This is
            acheived through the use of an inner function that's called 
            recursively.
            
          * In PowerShell 5.x, this function overcomes a quirk of Get-ChildItem's 
            -Depth parameter, which is that when a path containing one or more 
            wildcard characters is specified it causes the entire directory 
            tree to be recursed.
        
    .EXAMPLE  
        Get-ChildItemToDepth -Path "C:\Program*" -Depth 4 -Filter "*.dll" -File
                
        # Recursively iterate any path matching "C:\Program*" up to four 
        # directories deep, returning DLL files.
    
    .LINK
        https://github.com/thecliguy/Get-ChildItemToDepth
        https://www.thecliguy.co.uk/2020/04/29/recursive-directory-traversal-to-a-specific-depth-in-powershell/
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True, ParameterSetName = 'Path')]
        [String]$Path,
        
        [parameter(Mandatory = $True, ParameterSetName = 'LiteralPath')]
        [String]$LiteralPath,
        
        [parameter(Mandatory = $False, ParameterSetName = 'Path')]
        [parameter(Mandatory = $False, ParameterSetName = 'LiteralPath')]
        [String]$Filter = "*",
        
        [parameter(Mandatory = $True, ParameterSetName = 'Path')]
        [parameter(Mandatory = $True, ParameterSetName = 'LiteralPath')]
        [Byte]$Depth,
                
        [parameter(Mandatory = $False, ParameterSetName = 'Path')]
        [parameter(Mandatory = $False, ParameterSetName = 'LiteralPath')]
        [Switch]$File
    )
    
    Function Get-ChildItemToDepthRecursive {
        # Copyright (C) 2020
        # Adam Russell <adam[at]thecliguy[dot]co[dot]uk> 
        # https://www.thecliguy.co.uk
        #
        # This function is a derivative work of the code from
        # https://stackoverflow.com/a/13253309, written by Chris Dent.
        #
        # Copyright (C) 2010, Chris Dent
        # https://www.indented.co.uk
        #
        # Licensed under the MIT License.

        [CmdletBinding()]
        param (
            [parameter(Mandatory = $True)]
            [String]$LiteralPath,
            
            [parameter(Mandatory = $False)]
            [String]$Filter = "*",
            
            [parameter(Mandatory = $True)]
            [Byte]$Depth,
                        
            [parameter(Mandatory = $False)]
            [Switch]$File,
            
            [parameter(Mandatory = $True)]
            [Byte]$CurrentDepth
        )
        
        # Design Notes:
        #   * This function only supports LiteralPath because the expansion of
        #     any non-literal wildcard characters in the initial path is 
        #     performed by the parent function.
        #   * The CurrentDepth parameter serves no purpose outside of this inner
        #     recursive function, that's why it's not exposed to the user 
        #     consumable function 'Get-ChildItemToDepth'.
        
        $CurrentDepth++
        
        (Get-ChildItem -LiteralPath $LiteralPath) | ForEach-Object {
            If ($PSBoundParameters['File']) {
                $_ | Where-Object { ($_.Name -Like $Filter) -and ($_.PSIsContainer -eq $False) }
            }
            Else {
                $_ | Where-Object { $_.Name -Like $Filter }
            }
            
            If ($_.PsIsContainer) {
                If ($CurrentDepth -le $Depth) {
                    # Callback to this function
                    
                    $GetChildItemToDepthParams = @{
                        Filter = $Filter
                        Depth = $Depth
                        CurrentDepth = $CurrentDepth
                        "LiteralPath" = $_.FullName
                    }
                                        
                    If ($PSBoundParameters['File']) {
                        $GetChildItemToDepthParams.add("File", $True)
                    }
                    
                    Get-ChildItemToDepthRecursive @GetChildItemToDepthParams
                }
                Else {
                    Write-Verbose $("Skipping GCI for Folder: $($_.FullName) " + `
                        "(Why: Current depth $CurrentDepth vs limit depth $Depth)")
                }
            }
        }
    }
        
    $GciParams = @{
        Depth = $Depth
    }
        
    If ($PSBoundParameters['File']) {
        $GciParams.add("File", $True)
    }
    
    If ($PSBoundParameters['Filter']) {
        $GciParams.add("Filter", $Filter)
    }
    
    If ($PSVersionTable.PSVersion.Major -lt 5) {
        $GciParams.add("CurrentDepth", 0)
    }
    
    # Resolve-Path returns no result if a path contains a wildcard and doesn't 
    # exist. Whereas if a path doesn't contain a wildcard and doesn't exist then
    # it throws a non-terminating error.
    #
    # To handle both conditions in a uniform way, errors are made terminating
    # and an 'ItemNotFoundException' exception will populate the return value 
    # variable with null.
    If ($PSBoundParameters['Path']) {
        $ResolvePathParams = @{Path = $Path; ErrorAction = "Stop"}
    }
    Else {
        $ResolvePathParams = @{LiteralPath = $LiteralPath; ErrorAction = "Stop"}
    }
    
    Try {$RootPath = @(Resolve-Path @ResolvePathParams)}
    Catch [System.Management.Automation.ItemNotFoundException] {$RootPath = $null}
    
    If ($RootPath) {
        $RootPath | ForEach-Object {
            $GciParams['LiteralPath'] = $_
            If ($PSVersionTable.PSVersion.Major -lt 5) {
                Get-ChildItemToDepthRecursive @GciParams
            }
            Else {
                Get-ChildItem @GciParams
            }
        }
    }
    Else {
        If ($PSBoundParameters['Path']) {
            Throw "Path not found: '$($Path)'"
        }
        Else {
            Throw "LiteralPath not found: '$($LiteralPath)'"
        }
    }
}