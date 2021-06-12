#
# Copyright 2021, Cédric Moreau <moreau dot cedric0 at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Get-ArubaCLInventoryDevices {

    <#
      .SYNOPSIS
      Get Devices on Aruba Central

      .DESCRIPTION
      Get Devices on Aruba Central

      .EXAMPLE
      Get-ArubaCLInventoryDevices -type IAP

      Get the 50th first iap on central

     .EXAMPLE
      Get-ArubaCLInventoryDevices -type IAP -limit 2000 -offset 0

      Get all the IAP (Limit 2000, starting offset at 0)
    #>

    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [ValidateSet('IAP', 'MAS')]
        [String]$type,
        [Parameter(Mandatory = $false)]
        [int]$offset,
        [Parameter(Mandatory = $false)]
        [int]$limit,
        [Parameter (Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$connection = $DefaultArubaCLConnection
    )

    Begin {
    }

    Process {



        $invokeParams = @{ }

        if ( $PsBoundParameters.ContainsKey('limit') ) {
            $invokeParams.add( 'limit', $limit )
        }
        if ( $PsBoundParameters.ContainsKey('offset') ) {
            $invokeParams.add( 'offset', $offset )
        }

        $uri = "/platform/device_inventory/v1/devices?sku_type=$type"

        $device = Invoke-ArubaCLRestMethod -uri $uri -method GET @invokeParams -connection $connection

        $device.devices

    }

    End {
    }
}