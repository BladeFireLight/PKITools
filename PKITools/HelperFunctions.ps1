function Get-Domain
{
    <#
            .Synopsis
            Return the current domain
            .DESCRIPTION
            Use .net to get the current domain
            .EXAMPLE
            Get-Domain
    #>
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.Domain])]
    Param
    ()
    Write-Verbose -Message 'Calling GetCurrentDomain()' 
    ([DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain())
}

function Get-ADPKIEnrollmentServers
{
    <#
            .Synopsis
            Return the Active Directory objects of the Certificate Authorites
            .DESCRIPTION
            Use .net to get the current domain
            .EXAMPLE
            Get-PKIEnrollmentServers
    #>
    [CmdletBinding()]
    [OutputType([adsi])]
    Param
    (
        [Parameter(Mandatory,HelpMessage='Domain To Query',Position = 0)]
        [string]
        $Domain
    )
    $QueryDN = 'LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,DC=' + $Domain -replace '\.', ',DC=' 
    Write-Verbose -Message "Querying [$QueryDN]"
    $result = [ADSI]$QueryDN
    if (-not ($CaEnrolmentServices.Name)) 
    {
        Throw "Unable to find any Certificate Authority Enrollment Services Servers on domain : $Domain" 
    }
    $result
}

function Get-ADCertificateTemplate
{
    <#
            .Synopsis
            Return the Active Directory objects of the Certificate Authorites
            .DESCRIPTION
            Use .net to get the current domain
            .EXAMPLE
            Get-PKIEnrollmentServers
    #>
    [CmdletBinding()]
    [OutputType([adsi])]
    Param
    (
        [Parameter(Mandatory,HelpMessage='Domain To Query',Position = 0)]
        [string]
        $Domain,
        [Parameter(Mandatory,HelpMessage='Template Name',Position = 1)]
        [string]
        $TemplateName
    )
    $QueryDN = "LDAP://CN=$TemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=" + $Domain -replace '\.', ',DC=' 
    Write-Verbose -Message "Querying [$QueryDN]"
    $result = [ADSI]$QueryDN
    if (-not ($result.Name)) 
    {
        Throw "Unable to find any Certificate Authority Enrollment Services Servers on domain : $Domain" 
    }
    $result
}

function Get-CaLocationString 
{
    <#
        .SYNOPSIS
        Gets the Certificate Authority Location String from active directory

        .DESCRIPTION
        Certificate Authority Location Strings are in the form of ComputerName\CAName This info is contained in Active Directory

        .PARAMETER CAName
        Name given when installing Active Directory Certificate Services

        .PARAMETER ComputerName
        Name of the computer with Active Directory Certificate Services Installed

        .PARAMETER Domain
        Domain to retreve data from

        .EXAMPLE
        get-CaLocationString -CAName MyCA
        Gets only the CA Location String for the CA named MyCA

        .EXAMPLE
        get-CaLocationString -ComputerName ca.contoso.com
        Gets only the CA Location String for server with the DNS name of ca.contoso.com

        .EXAMPLE
        get-CaLocationString -Domain contoso.com
        Gets all CA Location Strings for the domain contoso.com

        .NOTES
        Location string are used to connect to Certificate Authority database and extract data.

        .OUTPUTS
        [STRING[]]
    #>


    [CmdletBinding()]
    [OutputType([string])]
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
    $CAList = Get-CertificatAuthority @PSBoundParameters
    foreach ($ca in $CAList) 
    {
        ('{0}\{1}' -f $($ca.dNSHostName), $($ca.name))
    }
}
