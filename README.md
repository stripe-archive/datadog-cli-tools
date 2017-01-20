# Tools

## dashboards-using-metrics

```
dashboards-using-metrics some.metric.name
```

Returns the IDs of any screenboards or timeboards in wich the given regexp pattern is used in the definition.

## monitors-using-metrics

```
monitors-using-metrics some.metric.name
```

Returns the IDs of any monitors in wich the given regexp pattern is used in the `query`.

# Configuration

Create a file `~/.datadog.yaml` and make it look like the following:

```yaml
---
api_key: xxx
app_key: xxx
```
