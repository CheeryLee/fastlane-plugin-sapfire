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
Here is the list of all available actions. Read the documentation on each one by clicking on the action name.

| Argument                                                                     | Description                                                       | Supported platforms |
|------------------------------------------------------------------------------|-------------------------------------------------------------------|--------------------:|
| [`msbuild_select`](docs/actions/msbuild_select.md)                           | Changes the MSBuild executable to use                             |                 all |
| [`msbuild`](docs/actions/msbuild.md)                                         | Wraps all parameters and executes MSBuild                         |                 all |
| [`build_uwp_app`](docs/actions/build_uwp_app.md)                             | Alias for the `msbuild` action with additional parameters for UWP |             windows |
| [`update_uwp_signing_settings`](docs/actions/update_uwp_signing_settings.md) | Configures UWP package signing settings                           |             windows |
| [`dotnet_select`](docs/actions/dotnet_select.md)                             | Changes the dotnet executable to use                              |                 all |
| [`ensure_dotnet_version`](docs/actions/ensure_dotnet_version.md)             | Ensures the right version of .NET is installed and can be used    |                 all |

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