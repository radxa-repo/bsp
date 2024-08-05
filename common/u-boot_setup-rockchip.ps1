#!/usr/bin/env pwsh

using namespace System.IO

$ErrorActionPreference = "Stop"

Set-Variable ERROR_REQUIRE_FILE -Option Constant -Value -3
Set-Variable ERROR_ILLEGAL_PARAMETERS -Option Constant -Value -4
Set-Variable ERROR_REQUIRE_TARGET -Option Constant -Value -5

Function idbloader{
    if (Test-Path "$PSScriptRoot/idbloader-sd_nand.img"){
        return "$PSScriptRoot/idbloader-sd_nand.img"
    } else {
        return "$PSScriptRoot/idbloader.img"
    }
}

Function BuildSPINOR{
    if ((Test-Path "$PSScriptRoot/idbloader-spi_spl.img","$PSScriptRoot/u-boot.itb") -notcontains $false) {
        Write-Host "Building Upstream RK3399 SPI U-Boot..."
        $output = [FileStream]::new("spi.img", [FileMode]::Create, [FileAccess]::ReadWrite)

        $input = [FileStream]::new("$PSScriptRoot/idbloader-spi_spl.img", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(0, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $input = [FileStream]::new("$PSScriptRoot/u-boot.itb", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(512 * 768, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $output.SetLength(4MB)
        $output.Close()
    } elseif ((Test-Path "$PSScriptRoot/u-boot.itb") -notcontains $false) {
        Write-Host "Building Rockchip RK35 SPI U-Boot..."
        $output = [FileStream]::new("spi.img", [FileMode]::Create, [FileAccess]::ReadWrite)

        $input = [FileStream]::new((idbloader), [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(512 * 64, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $input = [FileStream]::new("$PSScriptRoot/u-boot.itb", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(512 * 16384, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $output.SetLength(16MB)
        $output.Close()
    } elseif ((Test-Path "$PSScriptRoot/idbloader-spi.img","$PSScriptRoot/uboot.img","$PSScriptRoot/trust.img") -notcontains $false) {
        Write-Host "Building Rockchip RK33 SPI U-Boot..."
        $output = [FileStream]::new("spi.img", [FileMode]::Create, [FileAccess]::ReadWrite)

        $input = [FileStream]::new("$PSScriptRoot/idbloader-spi.img", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(0, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $input = [FileStream]::new("$PSScriptRoot/uboot.img", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(512 * 4096, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $input = [FileStream]::new("$PSScriptRoot/trust.img", [FileMode]::Open, [FileAccess]::Read)
        $output.Seek(512 * 6144, [SeekOrigin]::Begin)
        $input.CopyTo($output)
        $input.Close()

        $output.SetLength(4MB)
        $output.Close()
    } else {
        Write-Host "Missing U-Boot binary!"
        return $ERROR_REQUIRE_FILE
    }
    Write-Host "SPI U-Boot has been created as spi.img under the current directory."
}

$ret = 0
switch ($args[0]) {
    "BuildSPINOR" {
        $ret = BuildSPINOR
    }
    "" {
        Write-Host "An operation is required.

Supported operations:
        BuildSPINOR
"
        $ret = $ERROR_ILLEGAL_PARAMETERS
    }
    default {
        Write-Host "$_ is not a supported operation!"
        $ret = $ERROR_ILLEGAL_PARAMETERS
    }
}

if ($ret -ne 0) {
    exit $ret
}
