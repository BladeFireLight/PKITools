# PKITools
Simple function to get certificate info from Active Directory Certificate Authority

## What it does
Get-CertificatAuthority : Get the Active Directory object of the Certficate Authorities configured to issue certificates on a Domain. 

Get-CaLocationString : Get the list of Certificate Authorities on the domain and output the Location Strings used to connect to them. Connection strings are in the form of Server\CAName 

Get-ADCertificateTemplate : Gets the Active Directory object of Certificate templates on a domain

Get-CertificateTemplateOID : Gets the OID of a specific template from Active Directory.

Get-IssuedCertificate : Gets Certificates issued by a Certificate Authority. Can be filtered by CommonName, Certificate Template or Days untill expire
NOTE: Due to required COM objects. Get-IssuedCertificate only works on Desktop Operating system, Server with Desktop, or Server Core with Active Directory Certificate Services installed.

## Why I created this
Looking on PowerShellGallery.com, I did not find anythign that could retrive certificates from a remote ADCS server and save them to a file. Or get a list of soon to expire Certificates

For example. to get all the certificates that will expire in the next two weeks from all CA's on the current Domain. 
~~~
Get-IssuedCertificate -ExpireInDays 14
~~~

Or to save off all the certificates issues for use by Desired State Configuration (DSC)
~~~
$DSCCerts = Get-IssuedCertificate -CertificateTemplateOid (Get-CertificateTemplateOID -Name 'DSCTemplate') -Properties 'Issued Common Name', 'Binary Certificate' 
foreach ($cert in $DSCCerts)
{
    set-content -path "c:\certs\$($cert.'Issued Common Name').cer" -Value $cert.'Binary Certificate' -Encoding Ascii
}
~~~

