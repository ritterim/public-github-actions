import { info } from '@actions/core';
import axios from 'axios';

export type VersionResult = { status: boolean, response: string }

export async function CheckWebAppHealth(
    webAppName: string, 
    healthUri: string,
    numberOfSeconds?: number): Promise<boolean> {
        if (!numberOfSeconds) numberOfSeconds = 300;

        const url = `https://${webAppName}.azurewebsites.net${healthUri}`;
        await new SleepTimer().sleep(10000);
        return await checkHealth(url, webAppName, numberOfSeconds);
}

export async function CompareVersionStrings(webAppName: string, expectedVersionString: string): Promise<VersionResult> {
    let result: VersionResult = { status: false, response: '' };
    const url = `https://${webAppName}.azurewebsites.net/_version`

    const response = await axios.get(url);
   
    if (response.data === expectedVersionString) {
        result.status = true;
        result.response = response.data; 
    }

    return result;
}

async function checkHealth(
    url: string,
    webAppName: string,
    numberOfSeconds: number): Promise<boolean> {
        const attempts = Math.round(numberOfSeconds / 10);
        let result = false; 

        for (let index = 1; index < attempts; index++) {
            info(`Checking ${webAppName}'s health status`);
            info(`Url: ${url}`);
            const appStatus = await axios.get(url);

            if (appStatus.status != 200) {
                info(`${webAppName} isn't ready yet`);
                info(`${webAppName} status code: ${appStatus.status}`);
                await new SleepTimer().sleep(10000);
                continue;
            }

            result = true;
            break;
        }

        return result;
}


class SleepTimer {
    public sleep (ms: number) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }
}

