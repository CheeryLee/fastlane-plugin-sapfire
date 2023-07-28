# 🔧 app_certification

Runs Windows App Certification Kit to ensure your app is safe and efficient before publishing it to Microsoft Store.
Requires installed Windows SDK before calling.

| Argument            | Description                                   | Env Var               | Default |
|---------------------|-----------------------------------------------|-----------------------|--------:|
| `appx_package_path` | The full path to a UWP package                | `SF_PACKAGE`          |         |
| `output_path`       | The path where to save report output XML-file | `SF_WACK_OUTPUT_PATH` |         |

Example:

```ruby
app_certification(
  appx_package_path: "./package.appx",
  output_path: "C:/Users/Admin/Desktop/check_output.xml"
)
```