import { info } from '@actions/core';
import axios from 'axios';

export async function CheckWebAppHealth(
    webAppName: string, 
    healthUri: string,
    numberOfSeconds?: number): Promise<boolean> {
        if(!numberOfSeconds) numberOfSeconds = 300;

        const url = `https://${webAppName}.azurewebsites.net${healthUri}`;
        return await checkHealth(url, webAppName, numberOfSeconds);
}

async function checkHealth(
    url: string,
    webAppName: string,
    numberOfSeconds: number): Promise<boolean> {
        const attempts = Math.round(numberOfSeconds / 10);
        let result = false;

        for (let index = 1; index < attempts; index++) {
            info(`Checking ${webAppName}'s health status`)
            info(`url: ${url}`)
            const appStatus = await axios.get(url, { validateStatus(status) {
                return (status >= 200 && status < 300) || status == 404
            }});

            if (appStatus.status != 200) {
                info(`${webAppName} isn't ready yet`);
                info(`${webAppName} status code: ${appStatus.status}`)
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

