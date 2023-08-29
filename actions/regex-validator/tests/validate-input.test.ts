import { describe } from 'node:test';
import { ValidateInput } from '../src/validate';

const regexExpression = "^[A-Za-z0-9 \.,]{1,80}$";
const input = 'cdbbdbsbz';

describe('Validate Input Required False', () => {
    it('returns valid if required is false', () => {
        var result = ValidateInput(input, regexExpression, false);
        expect(result.isValid).toBe(true)
    });


    it('returns false result if input is empty string', () => {
        const input = '';
        var result = ValidateInput(input, regexExpression, true);
       
        expect(result.isValid).toBe(false)
        expect(result.isMatched).toBe(false)
    });

    it('returns false result if input is empty string', () => {
        const input = '';
        var result = ValidateInput(input, regexExpression, false);
       
        expect(result.isMatched).toBe(true)
        expect(result.isValid).toBe(true)
    });

    it('returns invalid if require and input are empty', () => {
        var result = ValidateInput('', regexExpression, true);
       
        expect(result.isValid).toBe(false)
        expect(result.match).toBe('')
    })

});

describe('Validate Input Required True', () => {
    it('matched returns true result', () => {
        var result = ValidateInput(input, regexExpression, true);
       
        expect(result.isMatched).toBe(true)
    });

    it('matched returns true result with case insensitive', () => {
        const input = 'cdBbdbsSbZ';
        var result = ValidateInput(input, regexExpression, true);
       
        expect(result.isMatched).toBe(true)
    });

    it('returns result string', () => {
        var result = ValidateInput(input, regexExpression, true);
       
        expect(result.match).toBe(input)
    });
})

describe('Error Message', () => {
    it('displays error', () => {
        const regexExpression = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
        var result = ValidateInput(input, regexExpression, true);

        expect(result.isValid).toBe(false);
        expect(typeof result.error).toBe('string');
    })
})