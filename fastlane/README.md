fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios get_dev_certs
```
fastlane ios get_dev_certs
```
To create development certificate and provisioning profile
### ios export_app
```
fastlane ios export_app
```
To export app to AppStoreConnect
### ios upload_app
```
fastlane ios upload_app
```
To send app to AppStoreConnect
### ios release_app
```
fastlane ios release_app
```
Releases app to the AppStore

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
