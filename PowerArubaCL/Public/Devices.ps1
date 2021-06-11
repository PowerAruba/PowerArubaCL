#
# Copyright 2021, Cédric Moreau <moreau dot cedric0 at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Get-ArubaCLDevices {

    <#
      .SYNOPSIS
      Get Devices on Aruba Central

      .DESCRIPTION
      Get Devices on Aruba Central

      .EXAMPLE
      Get-ArubaCLDevices -type IAP

      Get the 50th first iap on central

     .EXAMPLE
      Get-ArubaCLDevices -type IAP -offset -limit

      Get all the IAP (Limit 2000, starting offset at 0)
    #>

    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [ValidateSet('IAP', 'MAS')]
        [String]$type,
        [Parameter(Mandatory = $false)]
        [switch]$offset,
        [Parameter(Mandatory = $false)]
        [switch]$limit
    )

    Begin {
    }

    Process {

        $uri = "/platform/device_inventory/v1/devices?sku_type=$type"

        if ( $PsBoundParameters.ContainsKey('offset') ) {
            $uri += "&offset=0"
        }

        if ( $PsBoundParameters.ContainsKey('limit') ) {
            $uri += "&limit=2000"
        }

        $device = Invoke-ArubaCLRestMethod -uri $uri -method GET

        $device.devices

    }

    End {
    }
}