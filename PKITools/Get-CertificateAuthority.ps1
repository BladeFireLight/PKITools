function Get-CertificatAuthority
{
<#
        .Synopsis
        Get list of Certificate Authorities from Active directory
        .DESCRIPTION
        Queries Active Directory for Certificate Authorities with Enrollment Services enabled
        .EXAMPLE
        Get-CertificatAuthority 
        .EXAMPLE
        Get-CertificatAuthority -CaName 'MyCA'
        .EXAMPLE
        Get-CertificatAuthority -ComputerName 'CA01' -Domain 'Contoso.com'
        .OUTPUTS
        System.DirectoryServices.DirectoryEntry
#>
    [CmdletBinding()]
    [OutputType([adsi])]
    Param
    (
        # Name given when installing Active Directory Certificate Services 
        [string[]]
        $CAName = $null,

        # Name of the computer with Active Directory Certificate Services Installed
        [string[]]
        $ComputerName = $null,

        # Domain to Search
        [String]
        $Domain = (Get-Domain).Name 
    )
    Write-Verbose $Domain
    ## If the DN path does not exist error message set as valid object 
    $CaEnrolmentServices = Get-ADPKIEnrollmentServers $Domain 
    $CAList = $CaEnrolmentServices.Children

    if($CAName)
    {
        $CAList = $CAList | Where-Object -Property Name -In  -Value $CAName
    }
    if ($ComputerName)
    {
        # Make FQDN
        [Collections.ArrayList]$List = @() 
        foreach ($Computer in $ComputerName) 
        { 
            if ($Computer -like "*.$Domain") 
            {
                $null = $List.add($Computer)
            } 
            else 
            {
                $null = $List.add("$($Computer).$Domain")
            }
        } # end foreach
        $CAList = $CAList | Where-Object -Property DNSHostName -In -Value $List
    }
    
    $CAList
}
