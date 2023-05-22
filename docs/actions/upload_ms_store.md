# 📦 upload_ms_store

Uploads new binary to Microsoft Partner Center. Works only on `windows` platform.
Be sure that you previously set up account credentials via `ms_credentials` action.

Despite the name of the action it's not fully automated because of API restrictions. It only uploads a binary but doesn't publish it.
You must do it manually.

For several reasons the process may return the fault submission status, but it's not the error in the usual sense.
For example, if an application must have the URL to privacy policy in submission options, it won't be filled up for 
the first time. Microsoft has deprecated some API objects and hasn't given a replacement. In such cases
the action successfully ends, but returns a yellow colored warning message and notifies that you must make your own decision about the
problematic aspects.  

| Argument                            | Description                                                                                        | Default |
|-------------------------------------|----------------------------------------------------------------------------------------------------|--------:|
| `app_id`                            | The Microsoft Store ID of an application                                                           |         |
| `path`                              | The file path to the package to be uploaded                                                        |         |
| `timeout`                           | The timeout for pushing to a server in seconds                                                     |       0 |
| `skip_waiting_for_build_processing` | If set to true, the action will only commit the submission and skip the remaining build validation |   false |

Example:

```ruby
upload_ms_store(
  path: "./MyPackage/Package.appxupload",
  app_id: "9PG71NABCDE",
  timeout: 60 # one minute
)
```