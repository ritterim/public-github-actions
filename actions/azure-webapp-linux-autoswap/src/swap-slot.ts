import { WebSiteManagementClient } from '@azure/arm-appservice';
import { ResourceManagementClient } from "@azure/arm-resources";
import { DefaultAzureCredential } from '@azure/identity';

export async function SwapApps(webAppName: string, subscriptionId: string, slot: string): Promise<void> {
    const credential = new DefaultAzureCredential();
    const client = new WebSiteManagementClient(credential, subscriptionId);
    const resourceClient = new ResourceManagementClient(credential, subscriptionId);
    let result = []
    for await (const item of resourceClient.resourceGroups.list()) {
      result.push(item);
    }
    
    const app = result.find(x => x.name == webAppName)

    if (app == null) {
      return
    }

    return await client.webApps.beginSwapSlotAndWait(
        /* resourceGroupName: */ `${app?.name}`,
        /* appName: */ `${webAppName}`,
        /* slot */ 'staging',
        /* slotSwapEntity */ { preserveVnet: false, targetSlot: slot });
}