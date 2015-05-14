# Powershell 2.0


# Stop and fail script when a command fails.
$ErrorActionPreference = "Stop"

# load library functions
$rsLibDstDirPath = "$env:rs_sandbox_home\RightScript\lib"
. "$rsLibDstDirPath\tools\PsOutput.ps1"
. "$rsLibDstDirPath\tools\ResolveError.ps1"
. "$rsLibDstDirPath\win\Version.ps1"

try
{
    # cleanup temp directory, if necessary.
    $tempDirPath = Join-Path "$env:temp" "SYS-Install-tools-AFECF233B0334CC7A3450B8059C51EF8"
    if (Test-Path "$tempDirPath")
    {
        rd -Force -Recurse "$tempDirPath"
    }
    
    ### begin install AlphaVSS
    $alphaVssDstDirPath = "$env:rs_sandbox_home\RightScript\tools\AlphaVSS"
    $alphaVssDllPath = Join-Path "$alphaVssDstDirPath" "AlphaVSS.Common.dll"
    if (Test-Path "$alphaVssDllPath")
    {
        Write-Output "Skipped AlphaVSS because it is already installed."
    }
    else
    {
        Write-Output "Installing AlphaVSS"
    
        # explode AlphaVSS into temporary directory using "tar" from RightScale sandbox.
        $alphaVssTgzPath = Join-Path "$env:RS_ATTACH_DIR" "AlphaVSS.tgz"
        $alphaVssTempDirPath = Join-Path "$tempDirPath" "AlphaVSS"
    
        $oldWorkingDirPath = $PWD
        if (-not(Test-Path "$tempDirPath"))
        {
            md "$tempDirPath" | Out-Null
        }
        cd "$tempDirPath"
        tar -xzf "$alphaVssTgzPath"
        cd "$oldWorkingDirPath"
        if (-not(Test-Path "$alphaVssTempDirPath"))
        {
            throw "Failed to explode expected ""$alphaVssTempDirPath"" directory"
        }

        if (-not(Test-Path "$alphaVssDstDirPath"))
        {
            md "$alphaVssDstDirPath" | Out-Null
        }
    
        Copy-Item -Force "$alphaVssTempDirPath\AlphaVSS.60.x64.dll" "$alphaVssDstDirPath"
        Copy-Item -Force "$alphaVssTempDirPath\AlphaVSS.Common.dll" "$alphaVssDstDirPath"
    }
    ### end install AlphaVSS
    
    ### begin install sync
    Write-Output "Installing sync"
    $syncDestDirPath = 'C:\Windows\system32'
    if (Test-Path "${syncDestDirPath}\sync.exe")
    {
        Write-Host "Sync is already installed."
    }
    else
    {
        $syncTgzPath = Join-Path $env:RS_ATTACH_DIR 'sync.tgz'
        cd "$env:RS_ATTACH_DIR"
        tar -xzf "$syncTgzPath"
        $syncPath = Join-Path $env:RS_ATTACH_DIR 'sync.exe'
    
        Move-Item "$syncPath" $syncDestDirPath
    
        # Supress Eula
        New-Item HKCU:\Software\Sysinternals -Force
        New-Item HKCU:\Software\Sysinternals\Sync -Force
        New-ItemProperty "HKCU:\Software\Sysinternals\Sync" -Force -Name "EulaAccepted" -Value 1 -PropertyType "DWord"
    }
    ### end install sync

}
catch
{
    ResolveError
    exit 1
}
