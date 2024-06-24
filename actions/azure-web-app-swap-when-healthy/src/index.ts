import { getInput, info, setFailed } from '@actions/core';
import ensureError from 'ensure-error';
import { CheckWebAppHealth } from './health-check.js';
import { SwapApps, swapResult } from './swap-slot.js';

try {
    const webAppName = getInput('azure_web_app_name');
    info(`Input.azure_web_app_name: ${webAppName}`);
    const webAppSlotName = getInput('azure_web_app_slot_name');
    info(`Input.azure_web_app_slot_name: ${webAppSlotName}`);
    const subscriptionId = getInput('azure_web_app_deploy_subscription_id');
    info(`Input.azure_web_app_deploy_subscription_id: ${subscriptionId}`);
    const healthUri = getInput('health_uri');
    const resourceGroup = getInput('azure_web_app_resource_group_name');
    info(`Input.azure_web_app_resource_group_name: ${resourceGroup}`);
    info(`Input.health_uri: ${healthUri}`);
    const healthTimeoutSeconds = getInput('health_timeout_seconds');
    info(`Input.health_timeout_seconds: ${healthTimeoutSeconds}`);

    info(`Checking status of slot: ${webAppSlotName}`);
    const convertedTimerNumber = parseInt(healthTimeoutSeconds);
    const initialHealthCheck = await CheckWebAppHealth(`${webAppName}-${webAppSlotName}`, healthUri, convertedTimerNumber);

    if (!initialHealthCheck) {
        setFailed('Error: initial health check failed');
        throw new Error;
    }

    info(`Health check for ${webAppName} passed...`);
    info(`Starting swap for ${webAppName}`);
    const result: swapResult = await SwapApps(webAppName, subscriptionId, resourceGroup, webAppSlotName, convertedTimerNumber);
    info(`Swap Result: ${result.status}`);

    if (!result.status) {
        setFailed(result.message);
        throw new Error;
    }

    info(`Checking health status for ${webAppName}`);
    const healthStatus = await CheckWebAppHealth(webAppName, healthUri, convertedTimerNumber);

    if (!healthStatus) {
        setFailed('Error: health check timed out');
        throw new Error;
    }

    info(`${webAppSlotName} was swapped`);
} catch(_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}