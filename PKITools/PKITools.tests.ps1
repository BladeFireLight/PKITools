Import-Module PKITools -Force

# describes the function Get-CertificateTemplateOID
InModuleScope 'PKITools' { 
    Describe 'Get-CertificateTemplateOID' {
      Context 'Domain is Found and Template Found' {
        Mock Get-Domain {
            $properties = @{
                'Name' = 'company.pri'
            }
            return New-Object -TypeName PSObject -Property $properties
        }
        Mock Get-ADCertificateTemplate {
            $properties = @{
                'msPKI-Cert-Template-OID' = '1.3.6.1.4.1.311.21.8.16187918.14945684.15749023.11519519.4925321.197.13392998.8282280'
            }
            return New-Object -TypeName PSObject -Property $properties
        }
        It 'runs without errors' {
          { Get-CertificateTemplateOID -Name 'TestTemplate' } | Should Not Throw
        }
        It 'Retuns Expected Value value' {
            Get-CertificateTemplateOID  -Name 'TestTemplate' | Should Not BeNullOrEmpty 
            Get-CertificateTemplateOID  -Name 'TestTemplate' | Should Be '1.3.6.1.4.1.311.21.8.16187918.14945684.15749023.11519519.4925321.197.13392998.8282280'
        }
      }
    }
    Describe 'Get-CertificatAuthority' {
        Mock Get-Domain {
            $properties = @{
                'Name' = 'company.pri'
            }
            return New-Object -TypeName PSObject -Property $properties
        }
        Mock Get-ADPKIEnrollmentServers {
            $child1 = @{
                'Name'      = 'company-CA1'
                'DNSHostName' = 'ca1.company.pri'
            }
            $child2 = @{
                'Name'      = 'company-CA2'
                'DNSHostName' = 'CA2.company.pri'
            }
            $child3 = @{
                'Name'      = 'company-CA3'
                'DNSHostName' = 'CA3.company.pri'
            }

            $properties = @{ 
                'Children' = (New-Object -TypeName PSObject -Property $child1), 
                (New-Object -TypeName PSObject -Property $child2), 
                (New-Object -TypeName PSObject -Property $child3)
            } 
            return New-Object -TypeName PSObject -Property $properties
        }
        Context 'Running without arguments - With Domain and CA entries' {
            It 'runs without errors' {
                {Get-CertificatAuthority} | Should Not Throw
            }
            It 'Returns a value when content exists' {
                (Get-CertificatAuthority).count | Should Not BeNullOrEmpty
            }
        }
        Context 'Runing without arguments - No domain' {
            Mock Get-Domain  { }
            It 'Throws when domain not found' {
                {Get-CertificatAuthority} | Should Throw 
            }
        }
        Context 'Runing without arguments - No CA in Domain' {
            Mock Get-ADPKIEnrollmentServers { }
            It 'does not return anything' {
                Get-CertificatAuthority| Should BeNullOrEmpty 
            }
        }
        Context 'Running with Single Arguments' {
            It 'return null or empty when nothing found' {
                Get-CertificatAuthority -CAName 'doesnotexist' | Should BeNullOrEmpty 
                Get-CertificatAuthority -ComputerName 'doesnotexist' | Should BeNullOrEmpty 
            }
            It 'Does not throw when nothing found' {
                { Get-CertificatAuthority -CAName 'doesnotexist' } | Should Not Throw
                { Get-CertificatAuthority -ComputerName 'doesnotexist' } | Should Not Throw 
            }
            It 'Finds and returns a value' {
                (Get-CertificatAuthority -CAName 'company-CA1') | Should Not BeNullOrEmpty
                (Get-CertificatAuthority -ComputerName 'ca1.company.pri') | Should Not BeNullOrEmpty
            }
            It -name 'Retuns correct CA Name' {
                (Get-CertificatAuthority -CAName 'company-CA1').name | Should be 'company-CA1'
                (Get-CertificatAuthority -CAName 'company-CA1').name | Should not be 'company-CA2'
            }
            It -name 'Retuns correct DNS Host Name' -test {
                (Get-CertificatAuthority -ComputerName 'ca1.company.pri').DNSHostName | Should be 'ca1.company.pri'
                (Get-CertificatAuthority -ComputerName 'ca1.company.pri').DNSHostName | Should not be 'ca2.company.pri'
            }
        }
        Context -Name 'Running with Single Array Arguments' -Fixture {
            It -name 'Retuns multiple' -test {
                (Get-CertificatAuthority -CAName 'company-CA1', 'company-CA2').count | Should be 2
            }
            It -name 'Retuns multiple' -test {
                (Get-CertificatAuthority -CAName 'company-CA1', 'company-CA2').Name -contains 'company-CA1' | Should be $true
            }
        }
    }
    Describe 'get-CaLocationString' {
        Mock Get-Domain {
            $properties = @{
                'Name' = 'company.pri'
            }
            return New-Object -TypeName PSObject -Property $properties
        }

      Context 'When no Value Returned by Get-CertificatAuthority' {
        Mock Get-CertificatAuthority { }
        It 'does not return anything' {
          get-CaLocationString | Should BeNullOrEmpty 
        }
      }
      Context 'When Single Values Retuned by Get-CertificatAuthority' {
         Mock Get-CertificatAuthority {  
            @{
                'dNSHostName' = 'DC.company.pri'
                'Name' = 'company.pri' 
            } 
        }
        It 'runs without errors' {
          { get-CaLocationString } | Should Not Throw
        }
        It 'Returns Expected value' {
          get-CaLocationString | Should Not BeNullOrEmpty 
          get-CaLocationString | Should Be 'DC.company.pri\company.pri' 
        }
      }
        Context 'When Multiple Values Retuned by Get-CertificatAuthority' {
        Mock Get-CertificatAuthority { 
             @(@{
                'dNSHostName' = 'CA1.company.pri'
                'Name' = 'MyCA1'
            },
            @{
                'dNSHostName' = 'CA2.company.pri'
                'Name' = 'MyCa2'
            } )
            }
            It 'runs without errors' {
              { get-CaLocationString } | Should Not Throw
            }
            It 'Returns Expected Value' {
              get-CaLocationString | Should NOT BeNullOrEmpty 
              (get-CaLocationString)[0] | Should Be  'CA1.company.pri\MyCA1' 
              (get-CaLocationString)[1] | Should Be  'CA2.company.pri\MyCA2' 
              (get-CaLocationString)[2] | Should BeNullOrEmpty 
            }
        }
    }

}