fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

Increment build number and commit. Run on release branch.

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Increment marketing version. Resets build number to 1. Pass type:'patch'|'minor'|'major' (default 'patch').

### ios verify_build

```sh
[bundle exec] fastlane ios verify_build
```

Verify build: archive only, no upload, no version bump. Use for fastlane setup validation.

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build the app and upload to TestFlight. No App Store submission.

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload App Store metadata and screenshots only (no binary).

### ios match_setup

```sh
[bundle exec] fastlane ios match_setup
```

Initial match setup. Run once. Generates dev + appstore certs/profiles and pushes to the cert repo.

### ios pull_metadata

```sh
[bundle exec] fastlane ios pull_metadata
```

Sync existing local metadata/screenshots from App Store Connect to local files.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
