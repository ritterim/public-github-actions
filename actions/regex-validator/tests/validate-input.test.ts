import {describe, expect, it} from '@jest/globals';
import { ValidateInput } from '../src/validate';

const regexExpression = "^[A-Za-z0-9 .,]{1,80}$";
const input = 'cdbbdbsbz';

describe('Validate Input Required False', () => {
    it('returns valid if required is false', () => {
        var result = ValidateInput(input, regexExpression, false, true);
        expect(result.isValid).toBe(true)
    });

    it('returns false result if input is empty string', () => {
        const input = '';
        var result = ValidateInput(input, regexExpression, true, true);
       
        expect(result.isValid).toBe(false)
        expect(result.isMatched).toBe(false)
    });

    it('returns false result if input is empty string', () => {
        const input = '';
        var result = ValidateInput(input, regexExpression, false, true);
       
        expect(result.isMatched).toBe(true)
        expect(result.isValid).toBe(true)
    });

    it('returns invalid if require and input are empty', () => {
        var result = ValidateInput('', regexExpression, true, true);
       
        expect(result.isValid).toBe(false)
        expect(result.match).toBe('')
    })

});

describe('Validate Input Required True', () => {
    it('matched returns true result', () => {
        var result = ValidateInput(input, regexExpression, true, true);
       
        expect(result.isMatched).toBe(true)
    });

    it('matched returns true result with case insensitive', () => {
        const input = 'cdBbdbsSbZ';
        var result = ValidateInput(input, regexExpression, true, true);
       
        expect(result.isMatched).toBe(true)
    });

    it('returns result string', () => {
        var result = ValidateInput(input, regexExpression, true, true);
       
        expect(result.match).toBe(input)
    });
})

describe('Error Message', () => {
    it('displays error', () => {
        const regexExpression = String.raw`!\\\\\\^!^!^(0|[1-9]\d*)$?`
        var result = ValidateInput('cdbbdbsbz', regexExpression, true, true);

        expect(result.isValid).toBe(false);
        expect(typeof result.error).toBe('string');
    })
})

describe('ValidateInput: Version RegEx', () => {
    const versionRegex = String.raw`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$`
    const cases = [
        {value: '0.0.1-alpha3', expected: true},
        {value: '0.900.85948-alpha3.2+abcdef', expected: true},
        {value: '1.2.0', expected: true},
        {value: '1.A.0', expected: false}
    ];
    it.each(cases)(
        "Case: '$value' returns $expected",
        ({value, expected}) => {
          let result = ValidateInput(value, versionRegex, true, true);
          expect(result.isMatched).toEqual(expected);
        }
      );
})

describe('ValidateInput: Case-Insensitive RegEx', () => {
    const versionRegex = String.raw`^release|debug$`
    const cases = [
        {value: 'release', expected: true},
        {value: 'RELEASE', expected: true},
        {value: 'Release', expected: true},
        {value: 'rElEAse', expected: true},
        {value: 'debug', expected: true},
        {value: 'DEBUG', expected: true},
        {value: 'Debug', expected: true},
        {value: 'dEbUg', expected: true},
        {value: 'debug!', expected: false},
        {value: '!release', expected: false},
    ];
    it.each(cases)(
        "Case: '$value' returns $expected",
        ({value, expected}) => {
          let result = ValidateInput(value, versionRegex, true, false);
          expect(result.isMatched).toEqual(expected);
        }
      );
})
