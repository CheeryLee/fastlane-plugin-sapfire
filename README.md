<p align="center">
    <a href="#">
        <img src="https://raw.githubusercontent.com/CheeryLee/fastlane-plugin-sapfire/master/assets/sapfire_logo.png" height="150" />
    </a>
</p>

# Sapfire
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/CheeryLee/fastlane-plugin-sapfire?display_name=tag&include_prereleases)

<br/>
<p align="center">An incredibly simple and fast way to automate building and deployment <b>Visual C++</b>, <b>.NET</b> and <b>UWP</b> apps</p>
<br/>

## What is it?
_Sapfire_ is a fastlane plugin that provides a bunch of actions to work with MSBuild, NuGet and Microsoft Store app submission.

**MSBuild** is a set of open-source build tools created by Microsoft. It is included with Visual Studio,
but also can be used independently via command-line interface.

**NuGet** is a package manager,  primarily used for packaging and distributing software written using the .NET.

**Microsoft Store** is a digital distribution platform for Windows.

## Goals
> Sapfire is in beta status at the moment. Not all declared features are supported right now. Look at the goals list
> down below to find info of interest.

- [x] Generic MSBuild support
- [ ] NuGet package building
- [ ] NuGet package uploading to various repositories
- [ ] Microsoft Store app submission

## Getting started
To get started working with plugin, add it to your `fastlane/Pluginfile`:
```ruby
gem "fastlane-plugin-sapfire", git: "https://github.com/fastlane/fastlane-plugin-sapfire" 
```

## Usage
### Platform support note
First of all it's important to denote that some of actions or their parameters (such as `msbuild` for UWP) are working
on Windows only. Currently _fastlane_ is not officially supported on this platform. Despite this fact it's still possible to run it.

Actions or parameters with such restriction contain the corresponding mark in documentation.

If you want to use them, be sure that the platform name of the build lanes is **windows**:
```ruby
platform :windows do
  # your lanes
end
```

### Help
Once installed, the information for an action can be printed out with this command:
```shell
fastlane action msbuild # or any action included with this plugin
```

### Actions
Here is the list of all available actions.

#### msbuild_select

Changes the MSBuild executable to use. Useful if you have multiple installed versions. Call it before using any other actions.

| Argument | Description                                             |
|----------|---------------------------------------------------------|
| `path`   | Path to MSBuild executable. Directly set in action call |

Example:

```ruby
msbuild_select("/cygdrive/c/Program\ Files/Microsoft\ Visual\ Studio/2022/Community/Msbuild/Current/Bin/MSBuild.exe")
```

#### msbuild

Wraps all parameters and executes MSBuild.

| Argument        | Description                                                                                                                            | Default |
|-----------------|----------------------------------------------------------------------------------------------------------------------------------------|---------|
| `project`       | Path to the SLN-project file                                                                                                           |         |
| `configuration` | Build configuration                                                                                                                    |         |
| `platform`      | Target platform                                                                                                                        |         |
| `restore`       | Restore project prior to build the actual targets                                                                                      | false   |
| `clean`         | Should the project be cleaned before building it?                                                                                      | false   |
| `jobs`          | A number of concurrent processes to use when building. Set it to -1 if you want to use up to the number of processors in the computer. | 1       |
| `properties`    | A dictionary of project properties to be set up, where the key is a property name and the value is it's value                          | empty   |

Example:

```ruby
msbuild(
  project: "/cygdrive/c/Projects/My_Project.sln",
  configuration: "Release",
  platform: "x86",
  clean: true,
  jobs: -1,
  properties: {
    "AppxBundlePlatforms": "x64"
  }
)
```

#### build_uwp_app

Alias for the `msbuild` action with additional parameters for UWP. Works only on `windows` platform.

| Argument                | Description                                                                                                                  | Default |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------|---------|
| `appx_output_path`      | Defines the folder to store the generated package artifacts. Relative path is a root folder where project is located.        | empty   |
| `appx_bundle_platforms` | Enables you to define the platforms to include in the bundle.                                                                |         |
| `build_mode`            | Package build mode. Use `SideloadOnly` for sideloading only or `StoreUpload` for generating the .msixupload/.appxupload file |         |
| `skip_codesigning`      | Build without package signing                                                                                                | false   |

Example:

```ruby
build_uwp_app(
  project: "/cygdrive/c/Projects/My_Project.sln",
  configuration: "Release",
  platform: "x86",
  appx_bundle_platforms: "x86|ARM",
  build_mode: "SideloadOnly"
)
```

#### update_uwp_signing_settings

Configures UWP package signing settings. Works only on `windows` platform. Values that would be set in this action will be applied to all next actions.

| Argument      | Description                                                                                  | Default |
|---------------|----------------------------------------------------------------------------------------------|---------|
| `certificate` | The path to the certificate to use. Relative path is a root folder where project is located. |         |
| `password`    | The password for the private key in the certificate                                          | empty   |
| `thumbprint`  | This value must match the thumbprint in the signing certificate or be an empty string        | empty   |

Example:

```ruby
update_uwp_signing_settings(
  certificate: "./WSACertificate.pfx"
)
```

## Working with SLN solution
In addition this plugin provides a parser module for Microsoft SLN file format.

To open a solution, run this:

```ruby
require "fastlane/plugin/sapfire/sln_project/sln_project"

root_block = Module.open("/cygdrive/c/Projects/My_Project.sln")
puts root_block.projects[0] # print name of the first subproject in solution
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```shell
rake
```

To automatically fix many of the styling issues, use
```shell
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please open a [GitHub issue](https://github.com/CheeryLee/fastlane-plugin-sapfire/issues).

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).

## License
This project is licensed under [the MIT license](LICENSE).