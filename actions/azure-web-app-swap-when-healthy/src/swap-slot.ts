import { WebSiteManagementClient } from '@azure/arm-appservice';
import { DefaultAzureCredential } from '@azure/identity';

export async function SwapApps(
  webAppName: string,
  subscriptionId: string,
  resourceGroup: string,
  slot: string): Promise<void> {
    const credential = new DefaultAzureCredential();
    const managementClient = new WebSiteManagementClient(credential, subscriptionId);

    return await managementClient.webApps.beginSwapSlotAndWait(
        /* resourceGroupName: */ `${resourceGroup}`,
        /* appName: */ `${webAppName}`,
        /* slot */ slot,
        /* slotSwapEntity */ { preserveVnet: false, targetSlot: 'production'});
}
