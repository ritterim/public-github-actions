interface Result {
    isMatched: boolean;
    match: string | null;
    isValid: boolean;
    error: string | number | null;
}
export declare function ValidateInput(input: string, regex_pattern: string, required: boolean): Result;
export {};
