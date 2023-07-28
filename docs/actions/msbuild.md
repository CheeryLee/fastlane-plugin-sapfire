# 🔨 msbuild

Wraps all parameters and executes MSBuild.

| Argument        | Description                                                                                                                            | Env Var                    | Default |
|-----------------|----------------------------------------------------------------------------------------------------------------------------------------|----------------------------|---------|
| `project`       | Path to the SLN-project file                                                                                                           | `SF_MSBUILD_PROJECT`       |         |
| `configuration` | Build configuration                                                                                                                    | `SF_MSBUILD_CONFIGURATION` |         |
| `platform`      | Target platform                                                                                                                        | `SF_MSBUILD_PLATFORM`      |         |
| `restore`       | Restore project prior to build the actual targets                                                                                      | `SF_MSBUILD_RESTORE`       | false   |
| `clean`         | Should the project be cleaned before building it?                                                                                      | `SF_MSBUILD_CLEAN`         | false   |
| `jobs`          | A number of concurrent processes to use when building. Set it to -1 if you want to use up to the number of processors in the computer. | `SF_MSBUILD_JOBS_COUNT`    | 1       |
| `properties`    | A dictionary of project properties to be set up, where the key is a property name and the value is it's value                          |                            | empty   |

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