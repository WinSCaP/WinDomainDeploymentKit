$CertificateLogDir = "C:\CertificateLog"
$CertificateOutputDir = "C:\CertificateStore"
$CertificateRequestOutput = "C:\Intermediate.req"
$RootCAFiles = "C:\RootCAFiles" 
$RootCERFile = "rootca.cer"
$CAConfig = "CN=IntermediateCA1,DC=DOMAIN,DC=TLD"  # Modify this according to your domain

# Install AD CS Role, Certification Authority, and Online Responder
Install-WindowsFeature ADCS-Cert-Authority, ADCS-Online-Cert, Web-Basic-Auth -IncludeManagementTools

# Import ADCS module
Import-Module ADCSAdministration

# Configure CA to issue certificates
$capolicy = @"
[Version]
Signature= "`$Windows NT$"

[PolicyStatementExtension]
Policies=InternalPolicy

[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice="Legal Notice: This certificate is for authorized use only."
URL="http://www.ncsc.nl/.well-known/security.txt"

[Certsrv_Server]
RenewalKeyLength=4096
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=3
CRLPeriod=Weeks
CRLPeriodUnits=26
CRLOverlapPeriod=Days
CRLOverlapUnits=1
LoadDefaultTemplates=0
"@

Set-Content -Path "C:\Windows\system32\capolicy.inf" -Value $capolicy



# Install and configure the intermediate CA
$params = @{
    CAType   = "EnterpriseSubordinateCa"
    CACommonName = "IntermediateCA1"
    LogDirectory = $CertificateLogDir
    DatabaseDirectory = $CertificateOutputDir
    OutputCertRequestFile = $CertificateRequestOutput

    
}
Install-AdcsCertificationAuthority @params -Force -OverwriteExistingKey

Set-Content -Path "C:\Windows\system32\CertSrv\CertEnroll\capolicy.inf" -Value $capolicy

Copy-Item -Path "$RootCAFiles\*" -Destination "C:\Windows\System32\CertSrv\CertEnroll"

New-Item -ItemType "directory" -Path "C:\inetpub\wwwroot" -Name "CertEnroll" -Force

Copy-Item -Path "$RootCAFiles\*.crl" -Destination "C:\inetpub\wwwroot\CertEnroll"
Copy-Item -Path "$RootCAFiles\*.cer" -Destination "C:\inetpub\wwwroot\CertEnroll"


$cert = Import-Certificate -FilePath "C:\Windows\System32\CertSrv\CertEnroll\$RootCERFile" -CertStoreLocation "Cert:\LocalMachine\Root" 

# Do not check for the Offline Root CRL
Certutil.exe -setreg ca\CRLFlags +CRLF_REVCHECK_IGNORE_OFFLINE


# Output the details of the imported certificate
Write-Host "Certificate imported successfully:"
Write-Host "Subject: $($cert.Subject)"
Write-Host "Issuer: $($cert.Issuer)"
Write-Host "Thumbprint: $($cert.Thumbprint)"
Write-Host "--------------------------------------"
Write-Host ""
Write-Host @"
1. Copy $CertificateRequestOutput to the Root CA
2. Sign the request
3. Export the issued file as p7b with underlying certs
4. Copy to the Intermediate
5. Rename to C:\InterSigned.p7b
6. Start the CA from the GUI and install the certificate
"@
Write-Host ""
Write-Host "--------------------------------------"

# Prompt the user
$userInput = Read-Host "Do you want to continue? (Y/N)"
$userInput.ToUpper()
# Check the user input
if ($userInput -eq 'Y') {
    Write-Host "Continuing execution..."
} else {
    Write-Host "Execution stopped. User did not confirm with 'Y'."
    Exit 1
}

# Path to your .p7b certificate file
$p7bFile = "C:\intersigned.p7b"
# Define the Intermediate Certificate Store Path
$certStorePath = "Cert:\LocalMachine\CA"
# Import the .p7b file into the Intermediate Certification Authorities store
$importedCerts = Import-Certificate -FilePath $p7bFile -CertStoreLocation $certStorePath

# Display details about the imported certificates
foreach ($cert in $importedCerts) {
    Write-Host "Imported Certificate: $($cert.Subject)"
}

# Start the CA service
Start-Service certsvc

# Get the hostname of the server
$hostname = $env:COMPUTERNAME

# Retrieve the domain part of the FQDN
$domain = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName

# Combine hostname and domain to get the FQDN
if ($domain -ne "") {
    $fqdn = "$hostname.$domain"
} else {
    $fqdn = $hostname
}

# Add the Online Responder to CA
Add-CAAuthorityInformationAccess -AddToCertificateAIA "http://${fqdn}/ocsp" -Force

# Restart IIS to apply the Basic Authentication configuration
Restart-Service IISAdmin, W3SVC -Force

Write-Host "Intermediate CA setup complete."
