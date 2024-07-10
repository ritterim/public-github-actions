import { getInput, info, setFailed } from '@actions/core';
import ensureError from 'ensure-error';
import { CheckWebAppHealth, CompareVersionStrings } from './health-check.js';
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
    const healthTimeoutSeconds = getInput('health_timeout_seconds');
    info(`Input.health_timeout_seconds: ${healthTimeoutSeconds}`);
    const expectedVersionString = getInput('expected_version_string');
    info(`Input: ${expectedVersionString}`);
    const convertedTimerNumber = parseInt(healthTimeoutSeconds);
    const initialHealthCheck = await CheckWebAppHealth(`${webAppName}`, healthUri, convertedTimerNumber);

    if (!initialHealthCheck) {
        setFailed(`Error: ${webAppName} was never became health`);
        throw new Error;
    }

    var versionResults = await CompareVersionStrings(webAppName, expectedVersionString);

    if (!versionResults.status) {
        const credential = new DefaultAzureCredential();
        const managementClient = new WebSiteManagementClient(credential, subscriptionId);

        managementClient.webApps.restartSlot(resourceGroup, webAppName, webAppSlotName);

        const healthCheck= await CheckWebAppHealth(`${webAppName}`, healthUri, convertedTimerNumber);

        if (!healthCheck) {
            setFailed(`Error: ${webAppName} was never became health`);
            throw new Error;
        }

        var followUpVersionResult = await CompareVersionStrings(webAppName, expectedVersionString);

        if (!followUpVersionResult.status) {
            setFailed(`Error: failed to get ${webAppName}'s version endpoint.`);
            throw new Error;
        }

        if (expectedVersionString != followUpVersionResult.response) {
            setFailed(`Error: ${webAppName} version doesn't match the expected result`);
            setFailed(`Error: Expect ${expectedVersionString}`);
            setFailed(`Error: Received ${followUpVersionResult.response}`);
            throw new Error;
        }
    }

    if (expectedVersionString != versionResults.response) {
        setFailed(`Error: ${webAppName} version doesn't match the expected result`);
        setFailed(`Error: Expect ${expectedVersionString}`);
        setFailed(`Error: Actual ${versionResults.response}`);
        throw new Error;
    }

    info(`${webAppName}'s hash matches expected results`);
    info(`Error: Expect ${expectedVersionString}`);
    info(`Error: Actual ${versionResults.response}`);
} catch(_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}