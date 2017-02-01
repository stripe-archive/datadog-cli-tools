# Tools

## dashboards-using-metrics

```
dashboards-using-metrics some.metric.name
```

Returns the IDs of any screenboards or timeboards in which the given regexp pattern is used in the definition.

## monitors-using-metrics

```
monitors-using-metrics some.metric.name
```

Returns the IDs of any monitors in which the given regexp pattern is used in the `query`.

# Configuration

Create a file `~/.datadog.yaml` and make it look like the following:

```yaml
---
api_key: xxx
app_key: xxx
templates:
  dashboard: 'http://url/dash/%{id}'
  screenboard: 'http://url/screen/%{id}'
  monitor: 'http://url/monitors#%{id}'
```

The templates are optional and default to just printing the id.