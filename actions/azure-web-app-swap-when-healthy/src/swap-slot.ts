import { WebSiteManagementClient } from '@azure/arm-appservice';
import { DefaultAzureCredential } from '@azure/identity';
import { info } from 'console';

export type swapResult = { status: boolean , message: string };

export async function SwapApps(
  webAppName: string,
  subscriptionId: string,
  resourceGroup: string,
  slot: string,
  timer: number): Promise<swapResult> {
    const credential = new DefaultAzureCredential();
    const managementClient = new WebSiteManagementClient(credential, subscriptionId);

    var task = await managementClient.webApps.beginSwapSlotAndWait(
        /* resourceGroupName: */ `${resourceGroup}`,
        /* appName: */ `${webAppName}`,
        /* slot */ slot,
        /* slotSwapEntity */ { preserveVnet: false, targetSlot: 'production'});

    var message: swapResult = { status: false, message: `The swap API call failed to complete within ${timer} seconds.` };
    var convertedTimer = timer * 100;
    info(`Swap timer: ${convertedTimer} milliseconds`);
    var result = await swapSlotWithTimeLimit(convertedTimer, task, message);

    return result;
}

async function swapSlotWithTimeLimit(timeLimit: number, task: any, messageStatus: swapResult) {
  let timeout;
  const timeoutPromise = new Promise((resolve) => {
    timeout = setTimeout(() => {
      resolve(false);
    }, timeLimit);
  });

  const response = await Promise.race([task, timeoutPromise]);
  if (timeout) {
    clearTimeout(timeout);
  }

  if (!response) {
    return messageStatus
  }

  messageStatus.status = true;
  messageStatus.message = response;
  return messageStatus
}