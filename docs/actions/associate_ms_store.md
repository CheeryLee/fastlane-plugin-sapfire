# 🔨 associate_ms_store

Makes a local app manifest needed for Microsoft Store association. All data can be obtained from Microsoft Partner Center dashboard.

| Argument           | Description                                                                                                                    | Default |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------|---------|
| `manifest`         | Path to the APPX package manifest                                                                                              |         |
| `publisher`        | Describes the publisher information. It must match the publisher subject information of the certificate used to sign a package |         |
| `publisher_name`   | A friendly name for the publisher that can be displayed to users                                                               |         |
| `package_identity` | An unique name for the package                                                                                                 |         |

Example:

```ruby
associate_ms_store(
  manifest: "./MyProject/Package.appxmanifest",
  publisher: "CN=1234-XXXX-5678",
  publisher_name: "MegaSoft",
  package_identity: "ECA12345.MyProject",
)
```