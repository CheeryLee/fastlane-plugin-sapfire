# 🔨 msbuild_select

Changes the MSBuild executable to use. Useful if you have multiple installed versions. Call it before using any other actions.

| Argument | Description                                             |
|----------|---------------------------------------------------------|
| `path`   | Path to MSBuild executable. Directly set in action call |

Example:

```ruby
msbuild_select("/cygdrive/c/Program\ Files/Microsoft\ Visual\ Studio/2022/Community/Msbuild/Current/Bin/MSBuild.exe")
```