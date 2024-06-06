import { WebSiteManagementClient } from '@azure/arm-appservice';
import { DefaultAzureCredential } from '@azure/identity';

export async function SwapApps(
  webAppName: string,
  subscriptionId: string,
  slot: string): Promise<void> {
    const credential = new DefaultAzureCredential();
    const managementClient = new WebSiteManagementClient(credential, subscriptionId);
    let webApps = [];
    for await (const item of managementClient.webApps.list()) {
      webApps.push(item);
    }
    
    const app = webApps.find(x => x.name == webAppName);

    if (app == null) {
      return;
    }

    return await managementClient.webApps.beginSwapSlotAndWait(
        /* resourceGroupName: */ `${app.resourceGroup}`,
        /* appName: */ `${app.name}`,
        /* slot */ 'staging',
        /* slotSwapEntity */ { preserveVnet: false, targetSlot: slot });
}
