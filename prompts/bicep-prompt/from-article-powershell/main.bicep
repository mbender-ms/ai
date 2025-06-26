@description('Location for all resources.')
param location string = 'South Central US'

@description('The name of the hub virtual network.')
param vnetHubName string = 'vnet-hub'

@description('The address prefix for the hub virtual network.')
param vnetHubAddressPrefix string = '10.0.0.0/16'

@description('The name of the spoke virtual network.')
param vnetSpokeName string = 'vnet-spoke'

@description('The address prefix for the spoke virtual network.')
param vnetSpokeAddressPrefix string = '10.1.0.0/16'

@description('The address prefix for the spoke subnet.')
param spokeSubnetAddressPrefix string = '10.1.0.0/24'

@description('The name of the Azure Firewall.')
param firewallName string = 'firewall'

@description('The name of the firewall policy.')
param firewallPolicyName string = 'firewall-policy'

@description('The name of the NAT gateway.')
param natGatewayName string = 'nat-gateway'

@description('The name of the Azure Bastion.')
param bastionName string = 'bastion'

@description('The name of the route table for the spoke network.')
param routeTableName string = 'route-table-spoke'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The name of the virtual machine in the spoke network.')
param vmName string = 'vm-spoke'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

// Variables
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var azureBastionSubnetName = 'AzureBastionSubnet'
var spokeSubnetName = 'subnet-private'
var publicIpFirewallName = 'public-ip-firewall'
var publicIpBastionName = 'public-ip-bastion'
var publicIpNatName = 'public-ip-nat'
var networkSecurityGroupName = 'nsg-1'
var networkInterfaceName = '${vmName}-nic'

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

var imageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

// Hub Virtual Network
resource vnetHub 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetHubName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetHubAddressPrefix
      ]
    }
    subnets: [
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
      {
        name: azureBastionSubnetName
        properties: {
          addressPrefix: '10.0.2.0/26'
        }
      }
    ]
  }
}

// Spoke Virtual Network
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetSpokeName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpokeAddressPrefix
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
        }
      }
    ]
  }
}

// Virtual Network Peering - Hub to Spoke
resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: vnetHub
  name: 'vnet-hub-to-vnet-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
  }
}

// Virtual Network Peering - Spoke to Hub
resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: vnetSpoke
  name: 'vnet-spoke-to-vnet-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

// Public IP for Azure Firewall
resource publicIpFirewall 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpFirewallName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Public IP for Azure Bastion
resource publicIpBastion 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpBastionName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Public IP for NAT Gateway
resource publicIpNat 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpNatName
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
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

// Firewall Policy Rule Collection Group
resource firewallPolicyRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
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
            name: 'allow-internet'
            sourceAddresses: [
              spokeSubnetAddressPrefix
            ]
            destinationAddresses: [
              '*'
            ]
            ipProtocols: [
              'TCP'
            ]
            destinationPorts: [
              '*'
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
        name: 'configuration'
        properties: {
          publicIPAddress: {
            id: publicIpFirewall.id
          }
          subnet: {
            id: '${vnetHub.id}/subnets/${azureFirewallSubnetName}'
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
  dependsOn: [
    firewallPolicyRuleCollectionGroup
  ]
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

// Update Azure Firewall Subnet with NAT Gateway
resource azureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnetHub
  name: azureFirewallSubnetName
  properties: {
    addressPrefix: '10.0.1.0/26'
    natGateway: {
      id: natGateway.id
    }
  }
  dependsOn: [
    firewall
  ]
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          publicIPAddress: {
            id: publicIpBastion.id
          }
          subnet: {
            id: '${vnetHub.id}/subnets/${azureBastionSubnetName}'
          }
        }
      }
    ]
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
        name: 'default-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Network Security Group for VM
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
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
            id: '${vnetSpoke.id}/subnets/${spokeSubnetName}'
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
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: imageReference
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

// VM Extension for TrustedLaunch
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (securityType == 'TrustedLaunch' && securityProfileJson.uefiSettings.secureBootEnabled && securityProfileJson.uefiSettings.vTpmEnabled) {
  parent: vm
  name: 'GuestAttestation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.LinuxAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
      }
    }
  }
}

// Outputs
output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output natGatewayPublicIP string = publicIpNat.properties.ipAddress
output bastionName string = bastion.name
output vmName string = vm.name
