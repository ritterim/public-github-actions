interface Result {
    isMatched: boolean,
    match: string | null,
    isValid: boolean,
    error: string | number | null
}

export function ValidateInput(
    input: string,
    regex_pattern: string,
    required: boolean): Result {
    let result: Result = {
        isMatched: false,
        match: input,
        isValid: false,
        error: null
    };
    var matchedPattern = matchRegexPattern(result, input, regex_pattern);

    if(required) {
        if(!input) {
            return result;
        }

        if(matchedPattern) {
            result.isValid = true;
            result.isMatched = true;
        }

        return result;
    } 

    if(!input || matchedPattern) {
        result.isValid = true;
        result.isMatched = true;
    }

    return result;
}

function matchRegexPattern (
    result: Result,
    input: string,
    regexPattern: string): boolean {
    try {
        var re = new RegExp(regexPattern);
        var regexResult = re.test(input)
        return regexResult;
    } catch (error: any) {
        result.error = "The input was not valid."
        return false;
    }
}