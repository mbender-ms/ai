@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the hub virtual network.')
param vnetHubName string = 'vnet-hub'

@description('Address prefix for the hub virtual network.')
param vnetHubAddressPrefix string = '10.0.0.0/16'

@description('Name of the default subnet in hub virtual network.')
param subnet1Name string = 'subnet-1'

@description('Address prefix for the default subnet.')
param subnet1Prefix string = '10.0.0.0/24'

@description('Address prefix for the Azure Bastion subnet.')
param bastionSubnetPrefix string = '10.0.1.0/26'

@description('Address prefix for the Azure Firewall subnet.')
param firewallSubnetPrefix string = '10.0.1.64/26'

@description('Name of the spoke virtual network.')
param vnetSpokeName string = 'vnet-spoke'

@description('Address prefix for the spoke virtual network.')
param vnetSpokeAddressPrefix string = '10.1.0.0/16'

@description('Name of the subnet in spoke virtual network.')
param spokeSubnetName string = 'subnet-private'

@description('Address prefix for the spoke subnet.')
param spokeSubnetPrefix string = '10.1.0.0/24'

@description('Name of the Azure Bastion host.')
param bastionName string = 'bastion'

@description('Name of the public IP for Azure Bastion.')
param bastionPublicIpName string = 'public-ip-bastion'

@description('Name of the Azure Firewall.')
param firewallName string = 'firewall'

@description('Name of the public IP for Azure Firewall.')  
param firewallPublicIpName string = 'public-ip-firewall'

@description('Name of the firewall policy.')
param firewallPolicyName string = 'firewall-policy'

@description('Name of the NAT gateway.')
param natGatewayName string = 'nat-gateway'

@description('Name of the public IP for NAT gateway.')
param natPublicIpName string = 'public-ip-nat'

@description('Name of the route table for spoke network.')
param routeTableName string = 'route-table-spoke'

@description('Name of the route to hub.')
param routeName string = 'route-to-hub'

@description('Name of the network security group.')
param nsgName string = 'nsg-1'

@description('Name of the virtual machine.')
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
param ubuntuOSVersion string = 'Ubuntu-2204'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_DS4_v2'

// Image reference configuration from example.bicep
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

// SSH configuration from example.bicep
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

// Public IP for NAT Gateway
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: natPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
        id: natPublicIp.id
      }
    ]
  }
}

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
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
    routes: [
      {
        name: routeName
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Spoke Virtual Network
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
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
          addressPrefix: spokeSubnetPrefix
          routeTable: {
            id: routeTable.id
          }
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Public IP for Bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: hubVnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

// Public IP for Firewall
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: firewallPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spoke-to-internet'
        priority: 100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-web'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              spokeSubnetPrefix
            ]
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: [
              '*'
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
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: firewallPublicIp.id
          }
          subnet: {
            id: hubVnet.properties.subnets[2].id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// Hub to Spoke Peering
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: 'vnet-hub-to-vnet-spoke'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowForwardedTraffic: true
  }
}

// Spoke to Hub Peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {  
  parent: spokeVnet
  name: 'vnet-spoke-to-vnet-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowForwardedTraffic: true
  }
}

// Network Interface for VM
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: spokeVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
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
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
}

// Outputs
output natGatewayPublicIp string = natPublicIp.properties.ipAddress
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output vmName string = vm.name
output hubVnetName string = hubVnet.name  
output spokeVnetName string = spokeVnet.name
