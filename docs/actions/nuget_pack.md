# 🔨 nuget_pack

Executes MSBuild to create a NuGet package. This action uses `restore` parameter under the hood to properly create the NuGet resources file.

In most cases _"Pack"_ task will run along with building the binaries. Thus, if there are no any conditions within it, you can skip calling `msbuild` action.

| Argument        | Description                                                                                                                            | Default |
|-----------------|----------------------------------------------------------------------------------------------------------------------------------------|---------|
| `project`       | Path to the SLN-project file                                                                                                           |         |
| `configuration` | Build configuration                                                                                                                    |         |
| `platform`      | Target platform                                                                                                                        |         |
| `clean`         | Should the project be cleaned before building it?                                                                                      | false   |
| `jobs`          | A number of concurrent processes to use when building. Set it to -1 if you want to use up to the number of processors in the computer. | 1       |
| `properties`    | A dictionary of project properties to be set up, where the key is a property name and the value is it's value                          | empty   |

Example:

```ruby
nuget_pack(
  project: "/cygdrive/c/Projects/My_Project.sln",
  configuration: "Release",
  platform: "x86",
  jobs: -1
)
```