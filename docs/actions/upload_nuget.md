# 📦 upload_nuget

Pushes a package to the server and publishes it. Be sure that you previously set up the path to dotnet executable via `dotnet_select` action.

| Argument  | Description                                                                                                                      | Env Var              | Default |
|-----------|----------------------------------------------------------------------------------------------------------------------------------|----------------------|--------:|
| `api_key` | The API key for the server                                                                                                       | `SF_NUGET_API_KEY`   |         |
| `source`  | The server URL. NuGet identifies a UNC or local folder source and simply copies the file there instead of pushing it using HTTP. | `SF_NUGET_SERVER`    |         |
| `timeout` | The timeout for pushing to a server in seconds                                                                                   | `SF_PUSHING_TIMEOUT` |       0 |
| `path`    | The file path to the package to be uploaded                                                                                      | `SF_PACKAGE`         |         |

Example:

```ruby
upload_nuget(
  path: "./package.nupkg",
  source: "https://nuget.pkg.github.com/NAMESPACE/index.json",
  api_key: "4003d786-cc37-4004-bfdf-c4f3e8ef9b3a",
  timeout: 60 # one minute
)
```