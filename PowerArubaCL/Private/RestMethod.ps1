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
        [psobject]$body,
        [Parameter(Mandatory = $false)]
        [int]$offset,
        [Parameter(Mandatory = $false)]
        [int]$limit
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
        #$access_token = ${DefaultArubaCLConnection}.access_token

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

        $sessionvariable = $DefaultArubaCLConnection.session
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
            $membertype = ($a | Get-Member -MemberType NoteProperty).name[0]
            #Check if number a item return by Central API (total)) is superior to return item (and generate a warning about use -limit)
            if ($response.total -gt $response.$membertype.count) {
                Write-Warning "There is extra items use -limit parameter to display"
            }
        }

        $response

    }

}