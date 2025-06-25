@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the hub virtual network.')
param hubVirtualNetworkName string = 'vnet-hub'

@description('The name of the spoke virtual network.')
param spokeVirtualNetworkName string = 'vnet-spoke'

@description('The name of the NAT gateway.')
param natGatewayName string = 'nat-gateway'

@description('The name of the Azure Firewall.')
param firewallName string = 'firewall'

@description('The name of the firewall policy.')
param firewallPolicyName string = 'firewall-policy'

@description('The name of the Azure Bastion host.')
param bastionHostName string = 'bastion'

@description('The name of the Virtual Machine.')
param vmName string = 'vm-spoke'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Name of the subnet in the spoke virtual network')
param spokeSubnetName string = 'subnet-private'

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'nsg-1'

@description('Name of the route table for spoke network')
param routeTableName string = 'route-table-spoke'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

// Variables for image reference
var imageReference = {
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

// Variables for networking
var hubAddressPrefix = '10.0.0.0/16'
var spokeAddressPrefix = '10.1.0.0/16'
var spokeSubnetAddressPrefix = '10.1.0.0/24'
var azureFirewallSubnetAddressPrefix = '10.0.1.0/26'
var azureBastionSubnetAddressPrefix = '10.0.2.0/27'

// Variables for VM configuration
var networkInterfaceName = '${vmName}NetInt'
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptystring', 0, 0)

// Public IP for NAT Gateway
resource publicIpNat 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'public-ip-nat'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// Public IP for Azure Firewall
resource publicIpFirewall 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'public-ip-firewall'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// Public IP for Azure Bastion
resource publicIpBastion 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'public-ip-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIpNat.id
      }
    ]
  }
}

// Hub Virtual Network
resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: hubVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: azureFirewallSubnetAddressPrefix
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: azureBastionSubnetAddressPrefix
        }
      }
    ]
  }
}

// Spoke Virtual Network
resource spokeVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: spokeVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeAddressPrefix
      ]
    }
    subnets: [
      {
        name: spokeSubnetName
        properties: {
          addressPrefix: spokeSubnetAddressPrefix
          routeTable: {
            id: routeTable.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

// Network Rule Collection Group
resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'spoke-to-internet'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-web'
            sourceAddresses: [
              spokeSubnetAddressPrefix
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '80'
              '443'
            ]
            ipProtocols: [
              'TCP'
            ]
          }
        ]
      }
    ]
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration'
        properties: {
          publicIPAddress: {
            id: publicIpFirewall.id
          }
          subnet: {
            id: '${hubVirtualNetwork.id}/subnets/AzureFirewallSubnet'
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionHostName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${hubVirtualNetwork.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: publicIpBastion.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
  }
}

// Route Table
resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'route-to-hub'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Virtual Network Peering - Hub to Spoke
resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVirtualNetwork
  name: 'vnet-hub-to-vnet-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVirtualNetwork.id
    }
  }
}

// Virtual Network Peering - Spoke to Hub
resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: spokeVirtualNetwork
  name: 'vnet-spoke-to-vnet-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVirtualNetwork.id
    }
  }
}

// Network Interface for VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${spokeVirtualNetwork.id}/subnets/${spokeSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: (securityType == 'TrustedLaunch') ? securityProfileJson : null
  }
}

// VM Extension for Trusted Launch
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (securityType == 'TrustedLaunch' && securityProfileJson.uefiSettings.secureBootEnabled && securityProfileJson.uefiSettings.vTpmEnabled) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

// Outputs
output adminUsername string = adminUsername
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output natGatewayPublicIp string = publicIpNat.properties.ipAddress
output firewallPublicIp string = publicIpFirewall.properties.ipAddress
output bastionPublicIp string = publicIpBastion.properties.ipAddress
