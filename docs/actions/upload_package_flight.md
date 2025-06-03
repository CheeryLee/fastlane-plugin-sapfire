# 🐛 upload_package_flight

Uploads new binary to Microsoft Partner Center as a new package flight. Works only on `windows` platform.
Be sure that you previously set up account credentials via `ms_credentials` action.

Tester groups can be created and modified in Microsoft Partner Center at _"Apps and games" -> "Engage" -> "Customer groups"_.
The ID of a group is placed in `groupId` URL argument.

The argument `group_ids` must be in JSON format: it's a root array where each element is a stringified ID.

| Argument                            | Description                                                                                        | Env Var              | Default |
|-------------------------------------|----------------------------------------------------------------------------------------------------|----------------------|--------:|
| `app_id`                            | The Microsoft Store ID of an application                                                           | `SF_APP_ID`          |         |
| `path`                              | The file path to the package to be uploaded                                                        | `SF_PACKAGE`         |         |
| `name`                              | An optional name that would be used as a flight name                                               | `SF_FLIGHT_NAME`     |         |
| `group_ids`                         | A list of tester groups who will get a new package                                                 |                      |         |
| `timeout`                           | The timeout for pushing to a server in seconds                                                     | `SF_PUSHING_TIMEOUT` |       0 |
| `skip_waiting_for_build_processing` | If set to true, the action will only commit the submission and skip the remaining build validation |                      |   false |
| `publish_immediate`                 | If set to true, the submission will be published automatically once the validation passes          |                      |   false |

Example:

```ruby
upload_package_flight(
  path: "./MyPackage/Package.appxupload",
  app_id: "9PG71NABCDE",
  timeout: 60, # one minute
  name: "build-123",
  group_ids: JSON.parse("[\"123456789\"]")
)
```