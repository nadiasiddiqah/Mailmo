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

### ios get_dev_certs

```sh
[bundle exec] fastlane ios get_dev_certs
```

To create development certificate and provisioning profile

### ios export_app

```sh
[bundle exec] fastlane ios export_app
```

To export app to AppStoreConnect

### ios upload_app

```sh
[bundle exec] fastlane ios upload_app
```

To send app to AppStoreConnect

### ios release_app

```sh
[bundle exec] fastlane ios release_app
```

Releases app to the AppStore

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
