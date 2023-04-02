# 🔨 dotnet_select

Changes the dotnet executable to use. Call it before using any other actions.

| Argument | Description                                            |
|----------|--------------------------------------------------------|
| `path`   | Path to dotnet executable. Directly set in action call |

Example:

```ruby
dotnet_select("C:/Program Files/dotnet/dotnet.exe")
```