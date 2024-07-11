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
    info(`Searching for: '${expectedVersionString}'`)
    let result: VersionResult = { status: false, response: '' };
    const response = await axios.get(versionUrl);

    if (response.data.includes(expectedVersionString)) {
        info(`Found '${expectedVersionString}' in the response.`);
        result.status = true;
        result.response = response.data;
    }

    info(`Did not find '${expectedVersionString}' in the response.`);

    return result;
}

async function checkHealth(
    url: string,
    webAppName: string,
    numberOfSeconds: number): Promise<boolean> {
    const attempts = Math.round(numberOfSeconds / 10);
    let result = false;

    info(`Checking ${webAppName} health status`);
    info(`Url: ${url}`);

    for (let index = 1; index < attempts; index++) {
        await new SleepTimer().sleep(10000);
        const appStatus = await axios.get(url);

        if (appStatus.status != 200) {
            info(`${webAppName} isn't ready yet, status code: ${appStatus.status}`);
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

