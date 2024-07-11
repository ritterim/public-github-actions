import { info } from '@actions/core';
import axios from 'axios';

export type VersionResult = { status: boolean, response: string }

export async function CheckWebAppHealth(
    webAppName: string,
    healthUrl: string,
    numberOfSeconds?: number
): Promise<boolean> {
    if (!numberOfSeconds) numberOfSeconds = 300;
    await new SleepTimer().sleep(10000);
    return await checkHealth(healthUrl, webAppName, numberOfSeconds);
}

export async function CheckVersion(
    versionUrl: string,
    expectedVersionString: string
): Promise<VersionResult> {
    info(`Checking version at: ${versionUrl}`);
    info(`Searching for: ${expectedVersionString}`)
    let result: VersionResult = { status: false, response: '' };
    const response = await axios.get(versionUrl);

    if (response.data.includes(expectedVersionString)) {
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
        info(`Checking ${webAppName} health status`);
        info(`Url: ${url}`);
        const appStatus = await axios.get(url);

        if (appStatus.status != 200) {
            info(`${webAppName} isn't ready yet`);
            info(`${webAppName} status code: ${appStatus.status}`);
            await new SleepTimer().sleep(10000);
            continue;
        }

        info(`${webAppName} is healthy.`);
        result = true;
        break;
    }

    return result;
}


class SleepTimer {
    public sleep(ms: number) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

