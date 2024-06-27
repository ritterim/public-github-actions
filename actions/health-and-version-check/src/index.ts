import { getInput, info, setFailed } from '@actions/core';
import ensureError from 'ensure-error';
import { CheckWebAppHealth } from './health-check.js';
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
    
    info(`Checking status of web app: ${webAppName}`);
    const convertedTimerNumber = parseInt(healthTimeoutSeconds);
    const initialHealthCheck = await CheckWebAppHealth(`${webAppName}`, healthUri, convertedTimerNumber);

    if (!initialHealthCheck.status || initialHealthCheck.response.trim() != expectedVersionString.trim()) {
        if (!initialHealthCheck.status) {
            info(`Info: ${webAppName}'s health check came back as unhealthy`);
        } else {
            info(`Info: ${webAppName}'s version string did not match the expected result`);
            info(`Info: expected result: ${expectedVersionString}`);
            info(`Info: ${webAppName}'s response: ${initialHealthCheck.response}`);
        }

        const credential = new DefaultAzureCredential();
        const managementClient = new WebSiteManagementClient(credential, subscriptionId);

        managementClient.webApps.restartSlot(resourceGroup, webAppName, webAppSlotName);
        const finalHealthCheck = await CheckWebAppHealth(`${webAppName}`, healthUri, convertedTimerNumber);

        if (!finalHealthCheck.status) {
            setFailed(`Error: ${webAppName} was not able to restart`);
            throw new Error;
        }

        if (finalHealthCheck.response.trim() != expectedVersionString.trim())  {
            setFailed(`Error: ${webAppName}'s doesn't match ${expectedVersionString}`);
            setFailed(`Error: expected result: ${expectedVersionString}`);
            setFailed(`Error: ${webAppName}'s response: ${initialHealthCheck.response}`);
            throw new Error;
        }

        info(`${webAppName}'s hash matches expected results`);
    }

    info(`${webAppName}'s hash matches expected results`);
} catch(_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}