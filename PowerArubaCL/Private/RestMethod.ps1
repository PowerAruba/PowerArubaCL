#
# Copyright 2021, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Invoke-ArubaCLRestMethod {

    <#
      .SYNOPSIS
      Invoke RestMethod with ArubaCL connection (internal) variable

      .DESCRIPTION
       Invoke RestMethod with ArubaCL connection variable (token...)

      .EXAMPLE
      Invoke-ArubaCLRestMethod -method "get" -uri "platform/device_inventory/v1/devices"

      Invoke-RestMethod with ArubaCL connection for get platform/device_inventory/v1/devices

      .EXAMPLE
      Invoke-ArubaCLRestMethod "platform/device_inventory/v1/devices"

      Invoke-RestMethod with ArubaCL connection for getplatform/device_inventory/v1/devices uri with default GET method parameter

      .EXAMPLE
      Invoke-ArubaCLRestMethod -method "post" -uri "platform/device_inventory/v1/devices" -body $body

      Invoke-RestMethod with ArubaCL connection for post platform/device_inventory/v1/devices uri with $body payload
    #>

    [CmdletBinding(DefaultParametersetname = "default")]
    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [String]$uri,
        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "PUT", "POST", "DELETE")]
        [String]$method = "get",
        [Parameter(Mandatory = $false)]
        [psobject]$body,
        [Parameter(Mandatory = $false)]
        [int]$offset,
        [Parameter(Mandatory = $false)]
        [int]$limit,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultArubaCLConnection
    )

    Begin {
    }

    Process {

        if ($null -eq $connection) {
            Throw "Not Connected. Connect to the Aruba Central with Connect-ArubaCL"
        }

        $Server = $connection.Server
        $headers = $connection.headers
        $invokeParams = $connection.invokeParams
        #$access_token = $connection.access_token
        $sessionvariable = $connection.session

        $fullurl = "https://${Server}/${uri}"
        if ($fullurl -NotMatch "\?") {
            $fullurl += "?"
        }

        if ( $PsBoundParameters.ContainsKey('offset') ) {
            $fullurl += "&offset=$offset"
        }

        if ( $PsBoundParameters.ContainsKey('limit') ) {
            $fullurl += "&limit=$limit"
        }

        try {
            if ($body) {

                Write-Verbose ($body | ConvertTo-Json)

                $response = Invoke-RestMethod $fullurl -Method $method -body ($body | ConvertTo-Json) -Headers $headers -WebSession $sessionvariable @invokeParams
            }
            else {
                $response = Invoke-RestMethod $fullurl -Method $method -Headers $headers -WebSession $sessionvariable @invokeParams
            }
        }

        catch {
            Show-ArubaCLException $_
            throw "Unable to use ArubaCL API"
        }

        #Only if limit is no set and $response.total is not empty
        if (-Not $limit -and $response.total) {
            #Search MemberType for count the number of response
            $membertype = ($response | Get-Member -MemberType NoteProperty).name[0]
            #Check if number a item return by Central API (total)) is superior to return item (and generate a warning about use -limit)
            if ($response.total -gt $response.$membertype.count) {
                Write-Warning "There is extra items use -limit parameter to display"
            }
        }

        $response

    }

}