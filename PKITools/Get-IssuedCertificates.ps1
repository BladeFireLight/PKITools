function Get-IssuedCertificate 
{
    <#
        .SYNOPSIS
        Get Issued Certificate data from one or more certificate athorities. 

        .DESCRIPTION
        Can get various certificate fileds from the Certificate Authority database. Usfull for exporting certificates or checking what is about to expire

        .PARAMETER ExpireInDays
        Maximum number of days from now that a certificate will expire. (Default: 21900 = 60 years) Can be a negative numbe to check for recent expirations

        .PARAMETER CAlocation
        Certificate Authority location string "computername\CAName" (Default gets location strings from Current Domain)

        .PARAMETER Properties
        Fields in the Certificate Authority Database to Export

        .PARAMETER CertificateTemplateOid
        Filter on Certificate Template OID (use Get-CertificateTemplateOID)

        .PARAMETER CommonName
        Filter by Issued Common Name

        .EXAMPLE
        Get-IssuedCertificate -ExpireInDays 14
        Gets all Issued Certificates Expireing in the next two weeks

        .EXAMPLE
        Get-IssuedCertificate -ExpireInDays -7
        Gets all Issued Certificates that Expired last week

        .EXAMPLE
        Get-IssuedCertificate -CAlocation CA1\MyCA
        Gets all Certificates Issued by CA1

        .EXAMPLE
        Get-IssuedCertificate -Properties 'Issued Common Name', 'Certificate Hash'
        Gets all Issued Certificates and outputs only the Common name and thumbprint

        .EXAMPLE
        Get-IssuedCertificate -CommonName S1, S2.contoso.com
        Gets Certificats issued to S1 and S2.contoso.com

        .EXAMPLE
        $DSCCerts = Get-IssuedCertificate -CertificateTemplateOid (Get-CertificateTemplateOID -Name 'DSCTemplate') -Properties 'Issued Common Name', 'Binary Certificate' 
        foreach ($cert in $DSCCerts)
        {
            set-content -path "c:\certs\$($cert.'Issued Common Name').cer" -Value $cert.'Binary Certificate' -Encoding Ascii
        }
        Get all certificates issued useing the DSCTemplate template and save them to the folder c:\certs named for the Common name of the certificate

   #>

 
    [CmdletBinding()]
    Param (
        
        # Maximum number of days from now that a certificate will expire. (Default: 21900 = 60 years)
        [Int]
        $ExpireInDays = 21900,
        
        # Certificate Authority location string "computername\CAName" (Default gets location strings from Current Domain)
        [String[]]
        $CAlocation = (get-CaLocationString),

        # Fields in the Certificate Authority Database to Export
        [String[]]
        $Properties = (
            'Issued Common Name', 
            'Certificate Expiration Date', 
            'Certificate Effective Date', 
            'Certificate Template', 
            #'Issued Email Address',
            'Issued Request ID', 
            'Certificate Hash', 
            #'Request Disposition',
            'Request Disposition Message', 
            'Requester Name', 
            'Binary Certificate' ),

        # Filter on Certificate Template OID (use Get-CertificateTemplateOID)
        [AllowNull()]
        [String]
        $CertificateTemplateOid,

        # Filter by Issued Common Name
        [AllowNull()]
        [String]
        $CommonName
    ) 
    
    foreach ($Location in $CAlocation) 
    {
        $CaView = New-Object -ComObject CertificateAuthority.View
        $null = $CaView.OpenConnection($Location)
        $CaView.SetResultColumnCount($Properties.Count)
    
        #region SetOutput Colum
        foreach ($item in $Properties)
        {
            $index = $CaView.GetColumnIndex($false, $item)
            $CaView.SetResultColumn($index)
        }
        #endregion

        #region Filters
        $CVR_SEEK_EQ = 1
        $CVR_SEEK_LT = 2
        $CVR_SEEK_GT = 16
    
        #region filter expiration Date
        $index = $CaView.GetColumnIndex($false, 'Certificate Expiration Date')
        $now = Get-Date
        $expirationdate = $now.AddDays($duedays)
        if ($duedays -gt 0)
        { 
            $CaView.SetRestriction($index,$CVR_SEEK_GT,0,$now)
            $CaView.SetRestriction($index,$CVR_SEEK_LT,0,$expirationdate)
        }
        else 
        {
            $CaView.SetRestriction($index,$CVR_SEEK_LT,0,$now)
            $CaView.SetRestriction($index,$CVR_SEEK_GT,0,$expirationdate)
        }
        #endregion filter expiration date

        #region Filter Template
        if ($CertificateTemplateOid)
        {
            $index = $CaView.GetColumnIndex($false, 'Certificate Template')
            $CaView.SetRestriction($index,$CVR_SEEK_EQ,0,$CertificateTemplateOid)
        }
        #endregion

        #region Filter Issued Common Name
        if ($CommonName)
        {
            $index = $CaView.GetColumnIndex($false, 'Issued Common Name')
            $CaView.SetRestriction($index,$CVR_SEEK_EQ,0,$CommonName)
        }
        #endregion

        #region Filter Only issued certificates
        # 20 - issued certificates
        $CaView.SetRestriction($CaView.GetColumnIndex($false, 'Request Disposition'),$CVR_SEEK_EQ,0,20)
        #endregion

        #endregion

        #region output each retuned row
        $CV_OUT_BASE64HEADER = 0 
        $CV_OUT_BASE64 = 1 
        $RowObj = $CaView.OpenView() 

        while ($RowObj.Next() -ne -1)
        {
            $Cert = New-Object -TypeName PsObject
            $ColObj = $RowObj.EnumCertViewColumn()
            $null = $ColObj.Next()
            do 
            {
                $displayName = $ColObj.GetDisplayName()
                # format Binary Certificate in a savable format.
                if ($displayName -eq 'Binary Certificate') 
                {
                    $Cert | Add-Member -MemberType NoteProperty -Name $displayName -Value $($ColObj.GetValue($CV_OUT_BASE64HEADER)) -Force
                } else 
                {
                    $Cert | Add-Member -MemberType NoteProperty -Name $displayName -Value $($ColObj.GetValue($CV_OUT_BASE64)) -Force
                }
            }
            until ($ColObj.Next() -eq -1)
            Clear-Variable -Name ColObj

            $Cert
        }
    }
}
