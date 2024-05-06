# WinDomainDeploymentKit

## Overview
The WinDomainDeploymentKit is a comprehensive collection of PowerShell scripts designed to automate the deployment and configuration of a complete Windows domain environment. This toolkit simplifies the setup of Active Directory, Certificate Authority, Distributed File System, Database Server, and System Center Configuration Manager.

## Features
- **Active Directory**: Automate the creation and configuration of Active Directory roles and features.
- **Certificate Authority**: Set up a robust Certificate Authority using best practices for security and management.
- **Distributed File System**: Configure DFS for file sharing and replication across the network.
- **Database Server**: Scripts to deploy and configure SQL Server for optimal performance in a domain environment.
- **System Center Configuration Manager (SCCM)**: Automate the deployment and initial configuration of SCCM for managing enterprise devices and applications.

## Getting Started
To use these scripts, follow the instructions below:

### Prerequisites
- Windows Server 2019 or later.
- PowerShell 5.1 or higher with administrative privileges.
- Appropriate licenses for Windows Server, SQL Server, and SCCM.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/WinSCaP/WinDomainDeploymentKit.git
2. Navigate to the repository directory:
   ```bash
   cd WinDomainDeploymentKit
3. Execute the scripts in the order specified by the documentation, starting with the Active Directory setup:
   ```bash
   .\ConfigureDomainProperties.ps1

### Usage

Each script is standalone and contains instructions at the top for specific usage and parameters required. Ensure you read these instructions carefully before executing the scripts.
Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

## To contribute:

    Fork the project.
    Create your feature branch (git checkout -b feature/AmazingFeature).
    Commit your changes (git commit -m 'Add some AmazingFeature').
    Push to the branch (git push origin feature/AmazingFeature).
    Open a pull request.

## License

Distributed under the MIT License. See LICENSE for more information.
Contact

## Acknowledgements

- [Microsoft PowerShell](https://docs.microsoft.com/en-us/powershell/)
- [Active Directory Documentation](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
- [Certificate Services Documentation](https://docs.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/)
- [DFS Documentation](https://docs.microsoft.com/en-us/windows-server/storage/dfs-namespaces/dfs-overview)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [System Center Configuration Manager Documentation](https://docs.microsoft.com/en-us/mem/configmgr/)


