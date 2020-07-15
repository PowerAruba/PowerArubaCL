#
# Copyright 2020, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Invoke-ArubaCLRestMethod {

    <#
      .SYNOPSIS
      Invoke RestMethod with ArubaCL connection (internal) variable

      .DESCRIPTION
    Invoke RestMethod with ArubaCL connection variable (token, csrf..)

      .EXAMPLE
      Invoke-ArubaCLRestMethod -method "get" -uri "rest/virtual-controller-ip"

      Invoke-RestMethod with ArubaCL connection for get rest/v1/rest/virtual-controller-ip

      .EXAMPLE
      Invoke-ArubaCLRestMethod "rest/v1/rest/virtual-controller-ip"

      Invoke-RestMethod with ArubaCL connection for get rest/v1/rest/virtual-controller-ip uri with default GET method parameter

      .EXAMPLE
      Invoke-ArubaCLRestMethod -method "post" -uri "rest/v1/rest/virtual-controller-ip" -body $body

      Invoke-RestMethod with ArubaCL connection for post rest/v1/rest/virtual-controller-ip uri with $body payloaders
    #>

    [CmdletBinding(DefaultParametersetname = "default")]
    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [String]$uri,
        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "PUT", "POST", "DELETE")]
        [String]$method = "get",
        [Parameter(Mandatory = $false)]
        [psobject]$body
    )

    Begin {
    }

    Process {

        if ($null -eq $DefaultArubaCLConnection) {
            Throw "Not Connected. Connect to the Aruba Central with Connect-ArubaCL"
        }

        $Server = ${DefaultArubaCLConnection}.Server
        $headers = ${DefaultArubaCLConnection}.headers
        $invokeParams = ${DefaultArubaCLConnection}.invokeParams
        $token = ${DefaultArubaCLConnection}.token
        $port = ${DefaultArubaCLConnection}.port

        $fullurl = "https://${Server}:${port}/${uri}"
        if ($fullurl -NotMatch "\?") {
            $fullurl += "?"
        }

        if ($token) {
            $fullurl += "&token=$token"
        }

        $sessionvariable = $DefaultArubaCLConnection.session
        try {
            if ($body) {
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
        $response

    }

}