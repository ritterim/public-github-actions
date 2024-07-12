import { getInput, info, setFailed } from '@actions/core';
import ensureError from 'ensure-error';
import { CheckVersion, CheckWebAppHealth } from './health-check.js';
import { WebSiteManagementClient } from '@azure/arm-appservice';
import { DefaultAzureCredential } from '@azure/identity';

try {
    const webAppName = getInput('azure_web_app_name');
    info(`Input.azure_web_app_name: ${webAppName}`);
    const webAppSlotName = getInput('azure_web_app_slot_name');
    info(`Input.azure_web_app_slot_name: ${webAppSlotName}`);
    const subscriptionId = getInput('azure_web_app_deploy_subscription_id');
    info(`Input.azure_web_app_deploy_subscription_id: ${subscriptionId}`);
    const resourceGroup = getInput('azure_web_app_resource_group_name');
    info(`Input.azure_web_app_resource_group_name: ${resourceGroup}`);
    const healthUri = getInput('health_uri');
    info(`Input.health_uri: ${healthUri}`);
    const versionUri = getInput('version_uri');
    info(`Input.health_uri: ${versionUri}`);
    const healthTimeoutSeconds = getInput('health_timeout_seconds');
    info(`Input.health_timeout_seconds: ${healthTimeoutSeconds}`);
    const expectedVersionString = getInput('expected_version_string');
    info(`Input: ${expectedVersionString}`);
    const convertedTimerNumber = parseInt(healthTimeoutSeconds);

    let baseUrl = `https://${webAppName}.azurewebsites.net`;
    if (webAppSlotName != 'production') {
        baseUrl = `https://${webAppName}-${webAppSlotName}.azurewebsites.net`;
    }
    const healthUrl = `${baseUrl}${healthUri}`;
    info(`Health URL: ${healthUrl}`);
    const versionUrl = `${baseUrl}${versionUri}`;
    info(`Version URL: ${versionUrl}`);

    const initialHealthCheck = await CheckWebAppHealth(`${webAppName}`, healthUrl, convertedTimerNumber);
    if (!initialHealthCheck) {
        setFailed(`Error: ${webAppName} never became healthy!`);
        throw new Error;
    }

    var versionResults = await CheckVersion(versionUrl, expectedVersionString);

    if (versionResults.status != 200 || !versionResults.isMatched) {
        if (versionResults.status != 200) {
            info(`Error: ${webAppName}'s status was not 200`);
        }

        if (!versionResults.isMatched) {
            info(`Error: ${webAppName} version doesn't match the expected result`);
        }

        info('Sending restart command for:');
        info(`  WebApp: ${webAppName}`);
        info(`  Slot: ${webAppSlotName}`);

        const credential = new DefaultAzureCredential();
        const managementClient = new WebSiteManagementClient(credential, subscriptionId);
        managementClient.webApps.restartSlot(resourceGroup, webAppName, webAppSlotName);

        info(`Restart command sent`);

        const healthCheck= await CheckWebAppHealth(`${webAppName}`, healthUri, convertedTimerNumber);

        if (!healthCheck) {
            setFailed(`Error: ${webAppName} never became healthy.`);
            throw new Error;
        }

        var followUpVersionResult = await CheckVersion(versionUrl, expectedVersionString);

        if (followUpVersionResult.status != 200) {
            setFailed(`Error: ${webAppName} version endpoint returned a ${followUpVersionResult.status} status code`);
            throw new Error;
        }

        if (!followUpVersionResult.isMatched) {
            setFailed(`Error: ${webAppName} version doesn't match the expected result`);
            setFailed(`Error: Expect ${expectedVersionString}`);
            setFailed(`Error: Received ${followUpVersionResult.response}`);
            throw new Error;
        }

        info(`${webAppName}'s expected_version_string was found in the response body`);
        info(`Expect ${expectedVersionString}`);
        info(`Actual ${versionResults.response}`);
    }

    if (versionResults.status != 200) {
        setFailed(`Error: ${webAppName} version endpoint returned a ${versionResults.status} status code`);
        throw new Error;
    }

    info(`${webAppName}'s expected_version_string was found in the response body`);
    info(`Expect ${expectedVersionString}`);
    info(`Actual ${versionResults.response}`);
} catch(_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}