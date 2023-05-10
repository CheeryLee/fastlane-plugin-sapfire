# 🔅 ms_credentials

Sets Azure AD credentials for further actions. Works only on `windows` platform.

Username should be used from Azure account, not from your Microsoft Partner Center account.
Usually it ends with `example.onmicrosoft.com` domain, where _example_ is a subdomain name that was chosen while creating Azure AD instance.

Call this action before any other actions that uses Azure AD API.

**Warning:** as you may have already noticed, there are some raw arguments: the account password and client secret.
Make sure that your environment is secure enough to work with them and not be at risk of a leak.
Unfortunately, at this moment there is no any other safer way to get an authorization token.

| Argument        | Description                                                                                  | Default |
|-----------------|----------------------------------------------------------------------------------------------|---------|
| `client_id`     | The ID of an application that would be associate to get working with Microsoft account       |         |
| `client_secret` | The unique secret string of an application that can be generated in Microsoft Partner Center |         |
| `tenant_id`     | The unique identifier of the Azure AD instance                                               |         |
| `username`      | The username of Azure AD account                                                             |         |
| `password`      | The password of Azure AD account                                                             |         |

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