import { WebSiteManagementClient } from '@azure/arm-appservice';
import { ResourceManagementClient } from '@azure/arm-resources';
import { DefaultAzureCredential } from '@azure/identity';

export async function SwapApps(
  webAppName: string,
  subscriptionId: string,
  slot: string): Promise<void> {
    const credential = new DefaultAzureCredential();
    const managementClient = new WebSiteManagementClient(credential, subscriptionId);
    const resourceClient = new ResourceManagementClient(credential, subscriptionId);
    let resourceGroups = [];
    for await (const item of resourceClient.resourceGroups.list()) {
      resourceGroups.push(item);
    }
    
    // TODO: The webAppName is the App Service name and needs to be more generic to get the proper resource group
    const app = resourceGroups.find(x => x.name == webAppName);

    if (app == null) {
      return;
    }

    return await managementClient.webApps.beginSwapSlotAndWait(
        /* resourceGroupName: */ `${app?.name}`,
        /* appName: */ `${webAppName}`,
        /* slot */ 'staging',
        /* slotSwapEntity */ { preserveVnet: false, targetSlot: slot });
}