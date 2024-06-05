import { getInput, info, setFailed } from "@actions/core";
import ensureError from "ensure-error";
import { CheckWebAppHealth } from "./health-check.js";
import { SwapApps } from "./swap-slot.js";

try {
    const webAppName = getInput('azure_web_app_name');
    info(`input.azure_web_app_name: ${webAppName}`);
    const webAppSlotName = getInput('azure_web_app_slot_name');
    info(`input.azure_web_app_slot_name: ${webAppSlotName}`);
    const subscriptionId = getInput('azure_web_app__deploy_subscription_id');
    info(`input.azure_web_app__deploy_subscription_id: ${subscriptionId}`);
    const healthUri = getInput('health_uri');
    info(`input.health_uri: ${healthUri}`);
    const healthTimeoutSeconds = getInput('health_timeout_seconds');
    info(`input.health_timeout_seconds: ${healthTimeoutSeconds}`);

    info('Checking status of of slows')
    const convertedTimerNumber = parseInt(healthTimeoutSeconds);
    var initialHealthCheck = await CheckWebAppHealth(webAppName, healthUri, convertedTimerNumber);

    if (!initialHealthCheck) {
        setFailed('initial health check failed')
    }

    info(`health check for ${webAppName} passed...`)
    info(`starting swap for ${webAppName}`);
    await SwapApps(webAppName, subscriptionId, webAppSlotName);

    info(`Checking health status for ${webAppName}`);
    var healthStatus = await CheckWebAppHealth(webAppName, healthUri, convertedTimerNumber);

    if (!healthStatus) {
        setFailed('Error: health check timed out')
    }

    info(`${webAppSlotName} was swapped`);

} catch(_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}