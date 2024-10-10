import { info } from '@actions/core';
import axios from 'axios';

export type VersionResult = { status: number | undefined, isMatched: boolean, response: string }

export async function CheckWebAppHealth(
    webAppName: string,
    healthUrl: string,
    numberOfSeconds?: number
): Promise<boolean> {
    if (!numberOfSeconds) numberOfSeconds = 300;
    return await checkHealth(healthUrl, webAppName, numberOfSeconds);
}

export async function CheckVersion(
    versionUrl: string,
    expectedVersionString: string,): Promise<VersionResult> {
    const attempts = 5;
    let result: VersionResult = { status: undefined, response: '', isMatched: false };

    info(`Checking version at: ${versionUrl}`);
    info(`Searching for: '${expectedVersionString}'`);

    for (let index = 1; index < attempts; index++) {
        await new SleepTimer().sleep(10000);
        const response = await axios.get(versionUrl);
        result.status = response.status;
        info(`Status Code from ${versionUrl}: ${response.status}`);

        if (response.status != 200) {
            info(`Did not find '${expectedVersionString}' in the response.`);
            continue;
        }
        
        const formattedResponse = JSON.stringify(response.data);
        result.response = formattedResponse;
        if (formattedResponse.includes(expectedVersionString)) {
            info(`Found '${expectedVersionString}' in the response.`);
            result.isMatched = true;
            break;
        } 

        info(`'${expectedVersionString}' was not found in the response.`);
        info(`response: '${result.response}'.`);
    }
    
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
        const appStatus = await axios.get(url, { validateStatus(status) {
            return (status >= 200 && status < 600)
        }});

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

