# Run on the Windows host in an elevated PowerShell (LAB ONLY: self-signed certificate, local Administrator).
# In a company domain WinRM is configured by GPO with Kerberos and CA-issued certificates instead.

# Enable WinRM (HTTP listener on 5985, service set to automatic)
Enable-PSRemoting -Force

# HTTPS listener on 5986 with a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * `
         -CertificateThumbPrint $cert.Thumbprint -Force

# Open the firewall for WinRM over HTTPS
New-NetFirewallRule -DisplayName "WinRM HTTPS (Ansible)" -Direction Inbound `
                    -Protocol TCP -LocalPort 5986 -Action Allow

# Let local admin accounts (not only domain accounts) use full admin rights remotely
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
                 -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force

# Check the listeners
winrm enumerate winrm/config/Listener
