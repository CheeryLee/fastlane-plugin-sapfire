# 🔨 nuget_pack

Executes MSBuild to create a NuGet package. This action uses `restore` parameter under the hood to properly create the NuGet resources file.

| Argument        | Description                                                                                                                            | Default |
|-----------------|----------------------------------------------------------------------------------------------------------------------------------------|---------|
| `project`       | Path to the SLN-project file                                                                                                           |         |
| `jobs`          | A number of concurrent processes to use when building. Set it to -1 if you want to use up to the number of processors in the computer. | 1       |

Example:

```ruby
nuget_pack(
  project: "/cygdrive/c/Projects/My_Project.sln",
  jobs: -1
)
```