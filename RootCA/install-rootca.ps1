<#
.SYNOPSIS
This script automates the setup of a standalone offline root Certificate Authority (CA) on a Windows Server environment.

.DESCRIPTION
This PowerShell script facilitates the creation and configuration of an offline root CA. It includes steps to:
- Write CA policy configurations to an INF file.
- Install the Active Directory Certificate Services role and its management tools.
- Configure and install the root CA using defined parameters.
- Start and manage the Certificate Services.
- Update registry settings for the CA, including validity periods and CRL distribution specifics.
- Add and configure new CRL and AIA distribution points.
- Export the root CA certificate for distribution.

.PARAMETER uri
The URI where the CRL and CA certificates will be published. This should be accessible by clients for certificate validation.

.PARAMETER CACommonName
The common name for the Certificate Authority. This name will be used to identify the CA in issued certificates.

.EXAMPLE
PS> .\SetupOfflineRootCA.ps1

This command runs the script to set up an offline root CA with predefined settings as specified within the script.

.NOTES
Ensure that you run this script with administrative privileges as it involves installation of Windows features and modifications to system settings.
Make sure to customize the parameters like `uri` and `CACommonName` as per your specific deployment requirements before running the script.

.LINK
For more information on these topics, visit the following Microsoft Learn pages:
- About Certificate Authorities: https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/install-the-certification-authority
- About certreq: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1
- About Group Policy Management: https://learn.microsoft.com/en-us/windows/client-management/mdm/group-policy-object-operations
#>

# Config

### Base URI for CRL and certificate retrieval
    $uri = "www.mycrldomain.com"

### Common name for the CA
    $CACommonName = "MyRootCA"

# CA Policy
$caPolicy = @"
[Version]
Signature="`$Windows NT$"

[InternalPolicy]
OID=1.1.1.1.1.1.2
URL=https://www.ncsc.nl/.well-known/security.txt

[CRLDistributionPoint]
Empty=True

[AuthorityInformationAccess]
Empty=True

[certsrv_server]
RenewalKeyLength=4096
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=10
CRLPeriod=Years
CRLPeriodUnits=1
CRLDeltaPeriod=Weeks
CRLDeltaPeriodUnits=4
ClockSkewMinutes=20
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=0
ForceUTF8=0
EnableKeyCounting=0
"@

# Write the CA policy to a file
Set-Content -Path "C:\Windows\CApolicy.inf" -Value $caPolicy

Write-Host "CA policy configuration file has been written."


# Install the Active Directory Certificate Services role with management tools
Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools
Write-Host "Active Directory Certificate Services role has been installed."

# Certificate installation parameters
$params = @{
    CAType              = "StandaloneRootCa"
    CryptoProviderName  = "RSA#Microsoft Software Key Storage Provider"
    KeyLength           = 4096
    HashAlgorithmName   = "SHA512"
    ValidityPeriod      = "Years"
    ValidityPeriodUnits = 10
    CACommonName        = $CACommonName
    DatabaseDirectory   = "C:\Windows\System32\CertLog"
}
# Install the offline root CA
Install-AdcsCertificationAuthority @params -Force
Write-Host "Offline root CA has been installed."

# Start the CA service
Restart-Service CertSvc
Write-Host "Certificate Authority service has been started."

# Display CA configuration and registry settings
Certutil -CAInfo
Certutil -getreg

# Setting Intermediate

# Modify certificate settings for issued certificates
certutil.exe -setreg ca\ValidityPeriodUnits 3
certutil.exe -setreg ca\ValidityPeriod Years

# Modify CRL settings
certutil.exe –setreg CA\CRLPeriodUnits 26
certutil.exe –setreg CA\CRLPeriod Weeks
certutil.exe –setreg CA\CRLDeltaPeriodUnits 0
certutil.exe –setreg CA\CRLDeltaPeriod Days
certutil.exe –setreg CA\CRLOverlapPeriodUnits 12
certutil.exe –setreg CA\CRLOverlapPeriod Hours
Write-Host "Certificate and CRL settings have been updated."

# Restart the CA service to apply changes
Restart-Service CertSvc
Write-Host "Certificate Authority service restarted to apply new settings."

# Get all CRL distribution points
$crls = Get-CACrlDistributionPoint

# Loop through each CRL Distribution Point and remove if it doesn't start with "C:\Windows"
foreach ($crl in $crls) {
    # Check if the CRL distribution point does not start with "C:\Windows"
    if ($crl.URI -notlike "C:\Windows*") {
        # Remove the CRL distribution point
        Remove-CACrlDistributionPoint -Uri $crl.URI -Force
        Write-Host "Removed CRL Distribution Point: $($crl.URI)"
    } else {
        Write-Host "Skipping CRL Distribution Point: $($crl.URI)"
    }
}

Add-CACRLDistributionPoint -Uri "http://$uri/CertEnroll/<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl" -AddToCertificateCdp -AddToCrlIdp -Force
Write-Host "New CRL distribution point has been added."

# Get all CRL distribution points
$aias = Get-CAAuthorityInformationAccess

# Loop through each CRL Distribution Point and remove if it doesn't start with "C:\Windows"
foreach ($aia in $aias) {
    # Check if the CRL distribution point does not start with "C:\Windows"
    if ($aia.URI -notlike "C:\Windows*") {
        # Remove the CRL distribution point
        Remove-CAAuthorityInformationAccess -Uri $aia.URI -Force
        Write-Host "Removed AuthorityInformationAccess: $($aia.URI)"
    } else {
        Write-Host "Skipping AuthorityInformationAccess: $($aia.URI)"
    }
}

Add-CAAuthorityInformationAccess -Uri "http://$uri/CertEnroll/<ServerDNSName>_<CaName><CertificateName>.crt" -AddToCertificateAia -Force
Write-Host "New CA Authority Information Access location has been added."

# Issue a new CRL
certutil.exe -crl
Write-Host "New CRL has been issued" 

# Set audit settings
certutil -setreg CA\AuditFilter 127

# Start the CA service
Restart-Service CertSvc
Write-Host "Certificate Authority service restarted after audit settings update."

# Export Root Certificate
$rootCertificateSubjectName = "CN=${CACommonName}"
$exportPath = "C:\Windows\system32\CertSrv\CertEnroll\${CACommonName}.cer" 

$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -eq $rootCertificateSubjectName}
# Check if the certificate exists
if ($cert) {
    # Export the certificate to a .cer file
    Export-Certificate -Cert $cert -FilePath $exportPath -Type CERT -Force
    Write-Host "Root certificate exported successfully to $exportPath"
} else {
    Write-Host "No certificate with subject name $rootCertificateSubjectName found in the store."
}

Write-Host "The setup of your Offline Root Certificate Authority (CA) is now complete."
Write-Host "You are now ready to proceed with the creation of an Intermediate Certificate Authority (CA)."
Write-Host "This Intermediate CA will handle day-to-day certificate issuance and management tasks within your organization's public key infrastructure (PKI)."
Write-Host "Please ensure the Offline Root CA is secured and disconnected from any networks to maintain its integrity and trustworthiness."
Write-Host "When ready, please refer to the appropriate documentation or follow established procedures to build and sign your Intermediate CA."
