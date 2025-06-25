@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Prefix for all resource names.')
param resourcePrefix string = 'test'

@description('Address prefix for the hub virtual network.')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the spoke virtual network.')
param spokeVnetAddressPrefix string = '10.1.0.0/16'

@description('Address prefix for the Azure Firewall subnet.')
param firewallSubnetAddressPrefix string = '10.0.1.0/26'

@description('Address prefix for the Azure Bastion subnet.')
param bastionSubnetAddressPrefix string = '10.0.2.0/27'

@description('Address prefix for the spoke private subnet.')
param spokeSubnetAddressPrefix string = '10.1.0.0/24'

@description('NAT Gateway idle timeout in minutes.')
param natGatewayIdleTimeout int = 4

@description('Virtual machine size.')
param vmSize string = 'Standard_D2s_v3'

@description('The Ubuntu version for the VM.')
@allowed([
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2204'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('Type of authentication to use on the Virtual Machine.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

// Variables
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

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${resourcePrefix}-vnet-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetAddressPrefix
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
    ]
  }
}

// Spoke Virtual Network
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${resourcePrefix}-vnet-spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-private'
        properties: {
          addressPrefix: spokeSubnetAddressPrefix
          routeTable: {
            id: routeTableSpoke.id
          }
          networkSecurityGroup: {
            id: nsgSpoke.id
          }
        }
      }
    ]
  }
}

// Public IP for NAT Gateway
resource natGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${resourcePrefix}-public-ip-nat'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: '${resourcePrefix}-nat-gateway'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: natGatewayIdleTimeout
    publicIpAddresses: [
      {
        id: natGatewayPublicIp.id
      }
    ]
  }
}

// Public IP for Azure Bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${resourcePrefix}-public-ip-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: '${resourcePrefix}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// Public IP for Azure Firewall
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${resourcePrefix}-public-ip-firewall'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: '${resourcePrefix}-firewall-policy'
  location: location
  properties: {}
}

// Rule Collection Group
resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
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
            name: 'spoke-internet-access'
            ipProtocols: ['TCP', 'UDP']
            sourceAddresses: [spokeSubnetAddressPrefix]
            destinationAddresses: ['*']
            destinationPorts: ['*']
          }
        ]
      }
    ]
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: '${resourcePrefix}-firewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
  dependsOn: [
    ruleCollectionGroup
  ]
}

// Route Table for Spoke
resource routeTableSpoke 'Microsoft.Network/routeTables@2023-09-01' = {
  name: '${resourcePrefix}-route-table-spoke'
  location: location
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// VNet Peering Hub to Spoke
resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: 'vnet-hub-to-vnet-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// VNet Peering Spoke to Hub
resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: spokeVnet
  name: 'vnet-spoke-to-vnet-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

// Network Security Group for Spoke
resource nsgSpoke 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${resourcePrefix}-nsg-spoke'
  location: location
  properties: {
    securityRules: []
  }
}

// Network Interface for VM
resource vmNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${resourcePrefix}-vm-spoke-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${spokeVnet.id}/subnets/subnet-private'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgSpoke.id
    }
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${resourcePrefix}-vm-spoke'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${resourcePrefix}-vm-spoke'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: authenticationType == 'password' ? null : linuxConfiguration
    }
    storageProfile: {
      imageReference: imageReference[ubuntuOSVersion]
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
  }
}

// Outputs
output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output natGatewayPublicIp string = natGatewayPublicIp.properties.ipAddress
output bastionHostname string = bastion.properties.dnsName
output vmPrivateIp string = vmNic.properties.ipConfigurations[0].properties.privateIPAddress
