# RegEx Validator

Validate a string value against a Regular Expression (RegEx) using `RegExp.test()`.

- [RegEx Validator](#regex-validator)
  - [Release Process](#release-process)
- [Example Workflow](#example-workflow)

## Release Process

Currently Github Actions does not build each project automatically. You will need to run `npm build` in the project you're submitting changes too. 

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
