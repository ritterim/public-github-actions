# persist-workspace

This action will help you to persist your workspace from job to job on your workflow! With that you will be able to split your jobs and parallelize them without the need to re-do that basic steps needed for all the jobs.

NOTE: The '.git' folder is excluded from the tarball because the '.git/config' file can contain sensistive information.

## Usage

This action use [actions/upload-artifact](https://github.com/actions/upload-artifact) and [actions/download-artifact](https://github.com/actions/download-artifact) under the hood.

### Persist the workspace

```yml
name: My CI

on:
  pull_request:

jobs:
  init:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
      - name: Install dependencies
        run: npm install
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: persist
```

### Retrieve a persisted workspace

```yml
name: My CI

on:
  pull_request:

jobs:
  init:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
      - name: Install dependencies
        run: npm install
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: persist

  build:
    needs: [init]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: retrieve
          artifact_name: ${{ needs.init.outputs.artifact_name }}
      - name: Build the project
        run: npm run build
```


### Parallelize your jobs with the persisted workspace

```yml
name: My CI

on:
  pull_request:

jobs:
  init:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
      - name: Install dependencies
        run: npm install
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: persist

  test:
    needs: [init]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: retrieve
          artifact_name: ${{ needs.init.outputs.artifact_name }}
      - name: Run unit tests
        run: npm run test

  build:
    needs: [init]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
      - uses: ritterim/forks/persist-workspace@v1
        with:
          action: retrieve
          artifact_name: ${{ needs.init.outputs.artifact_name }}
      - name: Build the project
        run: npm run build
```

## Accepted inputs

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| action | `persist` or `retrieve` | `persist` | Whether you would like to persist or retrieve the workspace. |
| artifact_name | `string` | persisted-artifact | Name of the generated artifact. |
| retention_days | `number` | 3 | Number of days to keep the artifact. |
