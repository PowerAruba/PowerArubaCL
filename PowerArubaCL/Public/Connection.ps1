#
# Copyright 2020, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Connect-ArubaCL {

    <#
      .SYNOPSIS
      Connect to a Aruba Central

      .DESCRIPTION
      Connect to a Aruba Central

      .EXAMPLE
      Connect-ArubaCL -Server 192.0.2.1

      Connect to a Aruba Central with IP 192.0.2.1 using (Get-)credential

     .EXAMPLE
      Connect-ArubaCL -Server 192.0.2.1 -CL_ip_addr 192.0.2.2

      Connect to a Aruba Central with IP 192.0.2.1 and CL IP (query AP) 192.0.2.2 using (Get-)credential

      .EXAMPLE
      Connect-ArubaCL -Server 192.0.2.1 -SkipCertificateCheck

      Connect to an Aruba Central using HTTPS (without check certificate validation) with IP 192.0.2.1 using (Get-)credential

      .EXAMPLE
      $cred = get-credential
      PS C:\>Connect-ArubaCL -Server 192.0.2.1 -credential $cred

      Connect to a Aruba Central with IP 192.0.2.1 and passing (Get-)credential

      .EXAMPLE
      $mysecpassword = ConvertTo-SecureString aruba -AsPlainText -Force
      PS C:\>Connect-ArubaCL -Server 192.0.2.1 -Username admin -Password $mysecpassword

      Connect to a Aruba Central with IP 192.0.2.1 using Username and Password
  #>

    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [String]$region,
        [Parameter(Mandatory = $false)]
        [String]$Username,
        [Parameter(Mandatory = $false)]
        [SecureString]$Password,
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credentials,
        [Parameter(Mandatory = $true)]
        [String]$client_id,
        [Parameter(Mandatory = $true)]
        [String]$client_secret,
        [Parameter(Mandatory = $true)]
        [String]$customer_id
    )

    Begin {
    }

    Process {

        $connection = @{server = ""; session = ""; access_token = ""; headers = ""; invokeParams = ""}
        $invokeParams = @{ UseBasicParsing = $true; }

        #If there is a password (and a user), create a credentials
        if ($Password) {
            $Credentials = New-Object System.Management.Automation.PSCredential($Username, $Password)
        }

        #Not Credentials (and no password)
        if ($null -eq $Credentials) {
            $Credentials = Get-Credential -Message 'Please enter administrative credentials for your Aruba Central'
        }

        #for PowerShell (<=) 5 (Desktop), Enable TLS 1.1, 1.2
        if ("Desktop" -eq $PSVersionTable.PsEdition) {
            #Enable TLS 1.1 and 1.2
            Set-ArubaCLCipherSSL
        }
        else {
            #Core Edition
            #Remove -UseBasicParsing (Enable by default with PowerShell 6/Core)
            $invokeParams.remove("UseBasicParsing")
        }

        #Region
        switch ($region) {
            'EU-1' {
                $server = "eu-apigw.central.arubanetworks.com"
            }

        }
        $postParams = @{username = $Credentials.username; password = $Credentials.GetNetworkCredential().Password }

        $url = "https://${Server}/oauth2/authorize/central/api/login"
        $url += "?client_id=${client_id}"
        $headers = @{ Accept = "application/json"; "Content-type" = "application/json" }

        try {
            $response = Invoke-RestMethod $url -Method POST -Body ($postParams | ConvertTo-Json) -SessionVariable ArubaCL -headers $headers @invokeParams
        }
        catch {
            Show-ArubaCLException $_
            throw "Unable to login"
        }

        if ($response.status -ne "True") {
            $errormsg = $response.message
            throw "Unable to connect ($errormsg)"
        }

        #Search crsf cookie and session
        $cookies = $ArubaCL.Cookies.GetCookies($url)
        foreach ($cookie in $cookies) {
            #$cookie.name
            if ($cookie.name -eq "csrftoken") {
                $cookie_csrf = $cookie.value
            }
            if ($cookie.name -eq "session") {
                $cookie_session = $cookie.value
            }
        }

        $url = "https://${Server}/oauth2/authorize/central/api"
        $url += "?client_id=${client_id}&response_type=code&scope=all"
        $headers = @{ Accept = "application/json"; "Content-type" = "application/json" ; "Cookie" = $cookie_session ; "X-CSRF-TOKEN" = $cookie_csrf }
        $postParams = @{ customer_id = $customer_id }

        try {
            $response = Invoke-RestMethod $url -Method POST -Body ($postParams | ConvertTo-Json) -WebSession $ArubaCL -headers $headers @invokeParams
        }
        catch {
            Show-ArubaCLException $_
            throw "Unable to authorize"
        }

        $auth_code = $response.auth_code

        $url = "https://${Server}/oauth2/token"
        $url += "?client_id=${client_id}&client_secret=${client_secret}&grant_type=authorization_code&code=${auth_code}"
        $headers = @{ Accept = "application/json"; "Content-type" = "application/json" }

        try {
            $response = Invoke-RestMethod $url -Method POST -WebSession $ArubaCL -headers $headers @invokeParams
        }
        catch {
            Show-ArubaCLException $_
            throw "Unable to get token"
        }

        #Add Access token to headers
        $headers.add( "Authorization", "Bearer " + $response.access_token)

        $connection.server = $server
        $connection.session = $ArubaCL
        $connection.headers = $headers
        $connection.invokeParams = $invokeParams
        #TODO Need to store refresh_token and expires_in...
        $connection.access_token = $response.access_token

        Set-Variable -name DefaultArubaCLConnection -value $connection -scope Global

        $connection
    }

    End {
    }
}