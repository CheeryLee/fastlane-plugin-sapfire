# 🔅 ms_credentials

Sets Azure AD credentials for further actions. Works only on `windows` platform.

Username should be used from Azure account, not from your Microsoft Partner Center account.
Usually it ends with `example.onmicrosoft.com` domain, where _example_ is a subdomain name that was chosen while creating Azure AD instance.

Sapfire uses **OAuth 2.0 Resource Owner Password Credentials authentication method**, which handles the user password directly to sign in.
Account password and client secret are passing as raw arguments, therefore make sure that your environment is secure enough to work with them and not be at risk of a leak.
Also, referring to Microsoft documentation, if users need to use multi-factor authentication (MFA) to log in, they will be blocked instead and can't use the service.

Call this action before any other actions that uses Azure AD API.

| Argument        | Description                                                                                  | Env Var               | Default |
|-----------------|----------------------------------------------------------------------------------------------|-----------------------|---------|
| `client_id`     | The ID of an application that would be associate to get working with Microsoft account       | `SF_MS_CLIENT_ID`     |         |
| `client_secret` | The unique secret string of an application that can be generated in Microsoft Partner Center | `SF_MS_CLIENT_SECRET` |         |
| `tenant_id`     | The unique identifier of the Azure AD instance                                               | `SF_MS_TENANT_ID`     |         |
| `username`      | The username of Azure AD account                                                             | `SF_MS_USERNAME`      |         |
| `password`      | The password of Azure AD account                                                             | `SF_MS_PASSWORD`      |         |

Example:

```ruby
ms_credentials(
  client_id: "ABCDEF-557f-4ba9-98cb-123456789",
  client_secret: "n9Y8Q~sdfbFDSAd87ww2csd~xc57",
  username: "myaccount@example.onmicrosoft.com",
  password: "ABCDEF123456",
  tenant_id: "ABCDEF-5449-40f9-98fc-123456789"
)
```