#
# Copyright 2021, Alexis La Goutte <alexis.lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Update-ArubaCRefreshToken {
    Param(
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultArubaCLConnection
    )

    $url = "https://"+$connection.server+"/oauth2/token"
    $url += "?client_id="+$connection.token.client_id+"&client_secret="+$connection.token.client_secret+"&grant_type=refresh_token&refresh_token="+$connection.token.refresh_token
    $headers = @{ Accept = "application/json"; "Content-type" = "application/json" }

    Write-Verbose $url
    try {
        $response = Invoke-RestMethod $url -Method POST -WebSession $connection.session -headers $headers
    }
    catch {
        Show-ArubaCLException $_
        throw "Unable to get token"
    }
    Write-Verbose $response
    #Update Headers
    $connection.headers.Authorization = "Bearer " + $response.access_token

    #Update token..
    $connection.token.access_token = $response.access_token
    $connection.token.refresh_token = $response.refresh_token
    #Get when new token will be expire
    $connection.token.expire = [int](Get-Date -UFormat %s) + $response.expires_in
}