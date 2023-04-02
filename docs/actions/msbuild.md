# 🔨 msbuild

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