# 🔑 update_uwp_signing_settings

Configures UWP package signing settings. Works only on `windows` platform. Values that would be set in this action will be applied to all next actions.

| Argument      | Description                                                                                  | Env Var                       | Default |
|---------------|----------------------------------------------------------------------------------------------|-------------------------------|---------|
| `certificate` | The path to the certificate to use. Relative path is a root folder where project is located. | `SF_UWP_CERTIFICATE_PATH`     |         |
| `password`    | The password for the private key in the certificate                                          | `SF_UWP_CERTIFICATE_PASSWORD` | empty   |
| `thumbprint`  | This value must match the thumbprint in the signing certificate or be an empty string        |                               | empty   |

Example:

```ruby
update_uwp_signing_settings(
  certificate: "./WSACertificate.pfx"
)
```