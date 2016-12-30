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
