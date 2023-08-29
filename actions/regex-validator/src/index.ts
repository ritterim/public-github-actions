import { ValidateInput } from './validate.js';
import { getInput, info, setFailed, getBooleanInput, setOutput } from '@actions/core';
import ensureError from 'ensure-error';

try {
    const input = getInput('value');
    info(`input.value: ${input}`)
    const required = getBooleanInput('required');
    info(`input.required: ${required}`)
    const regexPattern = getInput('regex_pattern');
    info(`input.regex_pattern: ${regexPattern}`)
    const errorIfNotValid = getBooleanInput('error_if_not_valid');
    info(`input.error_if_not_valid: ${errorIfNotValid}`)

    var result = ValidateInput(input, regexPattern, required);

    if (errorIfNotValid) {
        if(!result.isValid) {
            setFailed(`Error: ${result.error}`)
        }
    } else {
        info(`Error: ${result.error}`)
    }

    if (required) {
        result.isMatched
            ? info('Input passed validation')
            : info('Input failed validation');
            
        info(`Input: ${result.match}`)
    }

    setOutput("matched", result.isMatched);    
} catch (_error: unknown) {
    const error = ensureError(_error);
    setFailed(error);
}