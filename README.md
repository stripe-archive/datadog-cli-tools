# Tools

## dashboards-using-metrics

Returns the IDs of any screenboards or timeboards in which the given regexp pattern is used in the definition.

```
Usage: ./dashboards-using-metrics.rb [options] <metric>
Example: ./dashboards-using-metrics.rb 'system.load.1'
    -v, --[no-]verbose               Run verbosely
    -c, --[no-]color                 Colorize output
    -d, --delay SECS                 Delay between requests (default: 0.5)
        --retries NUM                Number of retry attempts (default: 2)
        --config FILE                Specify config file
    -r, --[no-]regex                 Input is a regular expression (don't quote)
```

## get-downtime.rb

Get information about a given downtime:

```
Usage: ./get-downtime.rb [options]
    -v, --[no-]verbose               Run verbosely
    -c, --[no-]color                 Colorize output
    -d, --delay SECS                 Delay between requests (default: 0.5)
    -r, --retries NUM                Number of retry attempts (default: 2)
        --config FILE                Specify config file
```

## monitors-using-metrics

Returns the IDs of any monitors in which the given regexp pattern is used in the `query`.

```
Usage: ./monitors-using-metrics.rb [options] <metric>
Example: ./monitors-using-metrics.rb 'system.load.1'
    -v, --[no-]verbose               Run verbosely
    -c, --[no-]color                 Colorize output
    -d, --delay SECS                 Delay between requests (default: 0.5)
        --retries NUM                Number of retry attempts (default: 2)
        --config FILE                Specify config file
    -r, --[no-]regex                 Input is a regular expression (don't quote)
```

## query-metrics

Runs a query and returns the data points that would be charted:

```
Usage: ./query-metrics.rb [options] <query>
Example: ./query-metrics.rb 'avg:system.load.1{*}'
    -v, --[no-]verbose               Run verbosely
    -c, --[no-]color                 Colorize output
    -d, --delay SECS                 Delay between requests (default: 0.5)
    -r, --retries NUM                Number of retry attempts (default: 2)
        --config FILE                Specify config file
    -f, --from SPEC                  From date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to 30m ago
    -t, --to SPEC                    To date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to now
    -j, --json                       Output JSON instead of text
```

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
