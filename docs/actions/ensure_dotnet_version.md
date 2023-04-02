# 🔨 ensure_dotnet_version

Ensures the right version of .NET is installed and can be used. If `dotnet_select` action hasn't been called previously,
this action will try to use the system alias of `dotnet` executable.

| Argument  | Description                                                                                                                     | Default |
|-----------|---------------------------------------------------------------------------------------------------------------------------------|---------|
| `version` | .NET version to verify that is installed                                                                                        |         |
| `strict`  | Should the version be verified strictly (all 3 version numbers), or matching only the given version numbers (i.e. 6.0 == 6.0.x) | true    |

Example:

```ruby
ensure_dotnet_version(
  version: "6.0",
  strict: false
)
```