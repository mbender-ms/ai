// Tutorial: Use a NAT gateway with a hub and spoke network
// This template creates a hub-spoke network topology with NAT Gateway as described in:
// https://learn.microsoft.com/en-us/azure/nat-gateway/tutorial-hub-spoke-route-nat

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the NAT gateway.')
param natGatewayName string = 'nat-gateway'

@description('The name of the hub virtual network.')
param hubVnetName string = 'vnet-hub'

@description('The name of the spoke 1 virtual network.')
param spoke1VnetName string = 'vnet-spoke-1'

@description('The name of the spoke 2 virtual network.')
param spoke2VnetName string = 'vnet-spoke-2'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('SSH Key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('The size of the NVA VM')
param nvaVmSize string = 'Standard_B2s'

@description('The size of the test VMs')
param testVmSize string = 'Standard_B2s'

// NAT Gateway variables
var natGatewayPublicIPName = 'public-ip-nat'
var bastionPublicIPName = 'public-ip-bastion'

// Hub network variables
var hubVnetAddressSpace = '10.0.0.0/16'
var hubPrivateSubnetName = 'subnet-private'
var hubPrivateSubnetAddress = '10.0.0.0/24'
var hubPublicSubnetName = 'subnet-public'
var hubPublicSubnetAddress = '10.0.253.0/28'
var hubBastionSubnetAddress = '10.0.1.0/26'

// Spoke 1 network variables
var spoke1VnetAddressSpace = '10.1.0.0/16'
var spoke1SubnetName = 'subnet-private'
var spoke1SubnetAddress = '10.1.0.0/24'

// Spoke 2 network variables
var spoke2VnetAddressSpace = '10.2.0.0/16'
var spoke2SubnetName = 'subnet-private'
var spoke2SubnetAddress = '10.2.0.0/24'

// NVA variables
var nvaVmName = 'vm-nva'
var nvaPrivateIP = '10.0.0.10'
var nvaPublicIP = '10.0.253.10'
var nvaNsgName = 'nsg-nva'

// Spoke VM variables
var spoke1VmName = 'vm-spoke-1'
var spoke1NsgName = 'nsg-spoke-1'
var spoke2VmName = 'vm-spoke-2'
var spoke2NsgName = 'nsg-spoke-2'

// Route table variables
var hubRouteTableName = 'route-table-nat-hub'
var spoke1RouteTableName = 'route-table-nat-spoke-1'
var spoke2RouteTableName = 'route-table-nat-spoke-2'

// SSH configuration for Linux VM
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

// Create NAT Gateway public IP
resource natPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: natGatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// Create NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natPublicIP.id
      }
    ]
  }
}

// Create Bastion public IP
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPublicIPName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Create Hub Route Table
resource hubRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: hubRouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-via-nat-hub'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nvaPrivateIP
        }
      }
    ]
  }
}

// Create Spoke 1 Route Table
resource spoke1RouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: spoke1RouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-via-nat-spoke-1'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nvaPrivateIP
        }
      }
    ]
  }
}

// Create Spoke 2 Route Table
resource spoke2RouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: spoke2RouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-via-nat-spoke-2'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nvaPrivateIP
        }
      }
    ]
  }
}

// Create NSG for NVA
resource nvaNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nvaNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Create NSG for Spoke 1
resource spoke1Nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: spoke1NsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// Create NSG for Spoke 2
resource spoke2Nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: spoke2NsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// Create Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressSpace
      ]
    }
    subnets: [
      {
        name: hubPrivateSubnetName
        properties: {
          addressPrefix: hubPrivateSubnetAddress
          routeTable: {
            id: hubRouteTable.id
          }
        }
      }
      {
        name: hubPublicSubnetName
        properties: {
          addressPrefix: hubPublicSubnetAddress
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: hubBastionSubnetAddress
        }
      }
    ]
  }
}

// Create Spoke 1 Virtual Network
resource spoke1Vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: spoke1VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke1VnetAddressSpace
      ]
    }
    subnets: [
      {
        name: spoke1SubnetName
        properties: {
          addressPrefix: spoke1SubnetAddress
          routeTable: {
            id: spoke1RouteTable.id
          }
        }
      }
    ]
  }
}

// Create Spoke 2 Virtual Network
resource spoke2Vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: spoke2VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke2VnetAddressSpace
      ]
    }
    subnets: [
      {
        name: spoke2SubnetName
        properties: {
          addressPrefix: spoke2SubnetAddress
          routeTable: {
            id: spoke2RouteTable.id
          }
        }
      }
    ]
  }
}

// Create peering from hub to spoke 1
resource hubToSpoke1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hubVnet
  name: 'vnet-hub-to-vnet-spoke-1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spoke1Vnet.id
    }
  }
}

// Create peering from spoke 1 to hub
resource spoke1ToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spoke1Vnet
  name: 'vnet-spoke-1-to-vnet-hub'
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

// Create peering from hub to spoke 2
resource hubToSpoke2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hubVnet
  name: 'vnet-hub-to-vnet-spoke-2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spoke2Vnet.id
    }
  }
}

// Create peering from spoke 2 to hub
resource spoke2ToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spoke2Vnet
  name: 'vnet-spoke-2-to-vnet-hub'
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

// Create Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'bastion'
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
            id: '${hubVnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Create NVA primary network interface (public subnet)
resource nvaPrimaryNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${nvaVmName}-nic-primary'
  location: location
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/${hubPublicSubnetName}'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: nvaPublicIP
        }
      }
    ]
    networkSecurityGroup: {
      id: nvaNsg.id
    }
  }
}

// Create NVA secondary network interface (private subnet)
resource nvaSecondaryNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${nvaVmName}-nic-private'
  location: location
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/${hubPrivateSubnetName}'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: nvaPrivateIP
        }
      }
    ]
    networkSecurityGroup: {
      id: nvaNsg.id
    }
  }
}

// Create NVA Virtual Machine
resource nvaVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: nvaVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: nvaVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nvaPrimaryNic.id
          properties: {
            primary: true
          }
        }
        {
          id: nvaSecondaryNic.id
          properties: {
            primary: false
          }
        }
      ]
    }
    osProfile: {
      computerName: nvaVmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
}

// Create Spoke 1 VM network interface
resource spoke1VmNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${spoke1VmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${spoke1Vnet.id}/subnets/${spoke1SubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: spoke1Nsg.id
    }
  }
}

// Create Spoke 1 Virtual Machine
resource spoke1Vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: spoke1VmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: testVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spoke1VmNic.id
        }
      ]
    }
    osProfile: {
      computerName: spoke1VmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}

// Create Spoke 2 VM network interface
resource spoke2VmNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${spoke2VmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${spoke2Vnet.id}/subnets/${spoke2SubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: spoke2Nsg.id
    }
  }
}

// Create Spoke 2 Virtual Machine
resource spoke2Vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: spoke2VmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: testVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spoke2VmNic.id
        }
      ]
    }
    osProfile: {
      computerName: spoke2VmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}

// Outputs
output natGatewayPublicIP string = natPublicIP.properties.ipAddress
output bastionFqdn string = bastion.properties.dnsName
output adminUsername string = adminUsername
output nvaPrivateIP string = nvaPrivateIP
output spoke1VmPrivateIP string = spoke1VmNic.properties.ipConfigurations[0].properties.privateIPAddress
output spoke2VmPrivateIP string = spoke2VmNic.properties.ipConfigurations[0].properties.privateIPAddress
