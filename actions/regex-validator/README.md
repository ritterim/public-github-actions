# RegEx Validator

Validate a string value against a Regular Expression (RegEx) using `RegExp.test()`.

- [RegEx Validator](#regex-validator)
- [Example Workflow](#example-workflow)

# Example Workflow

```yml
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
    - name: Title
      with:
        value: 'Some test value'
        regex_pattern: '^[A-Za-z0-9 \.,]{1,80}$'
        required: false
```
