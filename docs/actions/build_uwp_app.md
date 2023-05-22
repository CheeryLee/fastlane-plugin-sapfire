# 🔨 build_uwp_app

Alias for the `msbuild` action with additional parameters for UWP. Works only on `windows` platform.

| Argument                | Description                                                                                                                  | Default |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------|---------|
| `appx_output_path`      | Defines the folder to store the generated package artifacts. Relative path is a root folder where project is located.        |         |
| `appx_output_name`      | Defines the name of the resulting package (without extension)                                                                |         |
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