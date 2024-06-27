import { info } from '@actions/core';
import axios from 'axios';

export type HealthResult = { status: boolean, response: string }

export async function CheckWebAppHealth(
    webAppName: string, 
    healthUri: string,
    numberOfSeconds?: number): Promise<HealthResult> {
        if (!numberOfSeconds) numberOfSeconds = 300;

        const url = `https://${webAppName}.azurewebsites.net${healthUri}`;
        await new SleepTimer().sleep(10000);
        return await checkHealth(url, webAppName, numberOfSeconds);
}

async function checkHealth(
    url: string,
    webAppName: string,
    numberOfSeconds: number): Promise<HealthResult> {
        const attempts = Math.round(numberOfSeconds / 10);
        let result: HealthResult = { status: false, response: '' };

        const https = require('https')
        const instance = axios.create({
        httpsAgent: new https.Agent({
            rejectUnauthorized: false
        })
        }) 
        for (let index = 1; index < attempts; index++) {
            info(`Checking ${webAppName}'s health status`);
            info(`Url: ${url}`);
            const appStatus = await instance.get(url, { validateStatus(status) {
                return (status >= 200 && status < 300) || status == 404;
            }});

            if (appStatus.status != 200) {
                info(`${webAppName} isn't ready yet`);
                info(`${webAppName} status code: ${appStatus.status}`);
                await new SleepTimer().sleep(10000);
                continue;
            }

            result.response = JSON.stringify(appStatus.data);
            result.status = true;
            break;
        }

        return result;
}

class SleepTimer {
    public sleep (ms: number) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }
}

