import axios from 'axios';

let numberOfPolls: number;
const pollIntervals = 10;

export async function CheckWebAppHealth(
    webAppName: string, 
    healthUri: string,
    monitorTime: number): Promise<boolean> {
    numberOfPolls = monitorTime * (60 / pollIntervals)
    const url = `https://${webAppName}.azurewebsites.net${healthUri}`;
    const result = await checkHealth(url);

    return result;
}

async function checkHealth(url: string, poll?: number) {
    if (!poll) {
        poll = 0;
    }

    if (poll > numberOfPolls) {
        return false;
    }

    await new SleepTimer().sleep(pollIntervals * 500);
    const result = await axios.get(url);

    if (result.status != 200) {
        checkHealth(url, poll + 1);
    }

    return true;
}

class SleepTimer {
    public sleep (ms: number) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }
}

