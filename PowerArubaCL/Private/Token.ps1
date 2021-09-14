#
# Copyright 2021, Alexis La Goutte <alexis.lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Update-ArubaCLRefreshToken {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'low')]
    Param(
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultArubaCLConnection
    )

    $url = "https://" + $connection.server + "/oauth2/token"
    $url += "?client_id=" + $connection.token.client_id + "&client_secret=" + $connection.token.client_secret + "&grant_type=refresh_token&refresh_token=" + $connection.token.refresh_token
    $headers = @{ Accept = "application/json"; "Content-type" = "application/json" }

    Write-Verbose $url
    if ($PSCmdlet.ShouldProcess($connection.token.client_id, 'Update Refresh Token')) {
        try {
            $response = Invoke-RestMethod $url -Method POST -WebSession $connection.session -headers $headers
        }
        catch {
            Show-ArubaCLException $_
            throw "Unable to get token"
        }
    }
    Write-Verbose $response
    #Update Headers
    $connection.headers.Authorization = "Bearer " + $response.access_token

    #Update token..
    $connection.token.access_token = $response.access_token
    $connection.token.refresh_token = $response.refresh_token
    #Get when new token will be expire
    $connection.token.expire = [int]((Get-Date -UFormat %s) -split ",")[0] + $response.expires_in
}

function Get-ArubaCLTokenStatus {
    <#
    .SYNOPSIS
    Get status of token

    .DESCRIPTION
    Get status of token so we don't need to keep reauthenticating

    .EXAMPLE
    Get-ArubaCLTokenStatus

    Get token status (expired or not)

    .EXAMPLE
    Get-ArubaCLTokenStatus -timeout 900

    Get token status (expired or not) on less of 900 seconds (15 minutes)
    #>

    Param(
        [Parameter(Mandatory = $false)]
        [int]$timeout = 0,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultArubaCLConnection
    )

    $expire = $connection.token.expire
    $now = [int]((Get-Date -UFormat %s) -split ",")[0]
    if (($expire - $now) -le $timeout) {
        # If token is expired, it should fail boolean
        return $false
    }
    else {
        return $true
    }
}