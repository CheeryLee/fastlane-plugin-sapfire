# 🔨 associate_ms_store

Makes a local app manifest needed for Microsoft Store association. All data can be obtained from Microsoft Partner Center dashboard.

This action uses Windows Azure Service Management API. You need to create Azure AD account and setup it before.

| Argument   | Description                              | Default |
|------------|------------------------------------------|---------|
| `manifest` | Path to the APPX package manifest        |         |
| `app_id`   | The Microsoft Store ID of an application |         |

Example:

```ruby
associate_ms_store(
  manifest: "./MyProject/Package.appxmanifest",
  app_id: "9PG71NABCDE"
)
```