# calculate-version-from-txt-using-github-run-id

A composite action which will calculate the version number for the build using a `version.txt` file for the major/minor values and the `github.run_id` value to calculate the patch value.

Read on for why you may want to use a different version calculation / workflow.

- [calculate-version-from-txt-using-github-run-id](#calculate-version-from-txt-using-github-run-id)
- [Patch Number Calculation](#patch-number-calculation)
- [Example](#example)

# Patch Number Calculation

The goal of the patch number calculation is to automatically assign a patch value to the SemVer at the start of the build.  This will make every build automatically get an unique version without having to constantly edit a `version.txt` file on every PR.

The problem we run into under GitHub Actions is that there is no monotonically increasing value at the repository level (or even organization level).  While there is the `github.run_number`; it is a unique counter per workflow in the repository and not overall.

So the next best solution is to simply use the `github.run` ID value.  However this value has some problems:

- Some build systems not allowing patch values over 65535 (unsigned 16-bit integer).
- The value is global for all of GitHub.
- It increments at a rate of about 10 million per day.

Given those limitations, we have setup a calculation that gives you a **new patch value about every 14-16 minutes**.  For many projects, you're probably not doing a release that frequently.

Your 'baseline' value should be some round number that is lower then the current global GitHub run ID value.  Such as `6100000000`.

Our current estimate is that the values will go from 1 to 65535 in the span of about 650 days.  If you don't have to worry about the 16-bit limit, you will never need to adjust your baseline.  If you do need to worry about it, consider bumping your baseline value every time you bump the major/minor values in the `version.txt` file.

# Example

This is an example of an internal build that tacks on the `github.run_number` which helps make frequent dev builds unique.  For a public release, you'd probably want to omit the 'version_suffix' input or set it to an empty string.

Note that you *must* have a `version.txt` file in the root of the repository with your major/minor value.

```
    steps:

      - name: Checkout Project
        uses: actions/checkout@v3
        with:
          ref: ${{ github.ref }}

      - name: Calculate Version
        id: version
        uses: ritterim/public-github-actions/actions/calculate-version-from-txt-using-github-run-id@v1.8.0
        with:
          version_suffix: "-alpha${{ github.run_number }}"
          github_run_id_baseline: 6100000000
```
