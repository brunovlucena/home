# Jamie SRE Chatbot - Logfire Instrumentation

This document describes the comprehensive Logfire instrumentation added to the Jamie SRE Chatbot for observability and monitoring.

## 🔥 What is Logfire?

Logfire is Pydantic's observability platform that provides:
- **Structured Logging**: Rich, structured logs with context
- **Distributed Tracing**: Track requests across services
- **Metrics**: Custom metrics and performance monitoring
- **Error Tracking**: Detailed error analysis and alerting

## 📊 Instrumentation Overview

### 1. **Ollama Client Instrumentation**
- **Spans**: `ollama.generate_response` - Tracks AI model requests
- **Metrics**: 
  - `ollama.response.duration` - Response time in seconds
  - `ollama.response.length` - Response length in characters
  - `ollama.requests.total` - Total requests count
  - `ollama.errors.total` - Error count
  - `ollama.errors.rate` - Error rate
- **Attributes**: Model name, prompt length, context length, success status

### 2. **Slack Event Instrumentation**

#### App Mentions (`@Jamie`)
- **Spans**: `slack.handle_mention`
- **Metrics**:
  - `slack.mentions.total` - Total mentions
  - `slack.mentions.duration` - Processing time
  - `slack.mentions.response_length` - Response length
  - `slack.mentions.empty` - Empty questions count
  - `slack.mentions.errors` - Error count
- **Attributes**: User ID, channel, question length, response length

#### Slash Commands (`/ask-jamie`)
- **Spans**: `slack.handle_slash_command`
- **Metrics**:
  - `slack.slash_commands.total` - Total commands
  - `slack.slash_commands.duration` - Processing time
  - `slack.slash_commands.response_length` - Response length
  - `slack.slash_commands.empty` - Empty questions count
  - `slack.slash_commands.errors` - Error count
- **Attributes**: User ID, channel ID, question length, response length

#### Direct Messages
- **Spans**: `slack.handle_direct_message`
- **Metrics**:
  - `slack.direct_messages.total` - Total DMs
  - `slack.direct_messages.duration` - Processing time
  - `slack.direct_messages.response_length` - Response length
  - `slack.direct_messages.errors` - Error count
- **Attributes**: User ID, message length, response length

#### App Home
- **Spans**: `slack.handle_app_home_opened`
- **Metrics**:
  - `slack.app_home.opens` - Home page opens
  - `slack.app_home.errors` - Error count
- **Attributes**: User ID

### 3. **Context Functions Instrumentation**

#### Channel Context
- **Spans**: `slack.get_channel_context`
- **Metrics**:
  - `slack.context.channel_requests` - Channel context requests
  - `slack.context.messages_count` - Recent messages count
  - `slack.context.errors` - Error count
- **Attributes**: Channel name, recent messages count, context length

#### DM Context
- **Spans**: `slack.get_dm_context`
- **Metrics**:
  - `slack.context.dm_requests` - DM context requests
  - `slack.context.dm_errors` - Error count
- **Attributes**: User name, context length

### 4. **Application Startup Metrics**
- **Metrics**:
  - `jamie.startup.attempts` - Startup attempts
  - `jamie.startup.success` - Successful startups
  - `jamie.startup.failures` - Failed startups
  - `jamie.startup.timestamp` - Startup timestamp
- **Attributes**: Environment, Ollama URL, model name

## 🚀 Setup Instructions

### 1. **Environment Variables**

Add these environment variables to your deployment:

```bash
# Required
LOGFIRE_TOKEN="your-logfire-token-here"
ENVIRONMENT="production"  # or "development", "staging"

# Optional (with defaults)
LOGFIRE_CONSOLE=false
LOGFIRE_SEND_TO_LOGFIRE=true
```

### 2. **Kubernetes Configuration**

The following files have been updated with Logfire configuration:

- **`k8s/deployment.yaml`**: Added `LOGFIRE_TOKEN` and `ENVIRONMENT` environment variables
- **`k8s/configmap.yaml`**: Added `ENVIRONMENT` configuration
- **`k8s/secrets.yaml`**: Added `LOGFIRE_TOKEN` secret template

### 3. **Docker Configuration**

The `Dockerfile` has been updated with Logfire environment variables.

## 📈 Monitoring Dashboard

### Key Metrics to Monitor

1. **Response Times**
   - `ollama.response.duration` - AI model response time
   - `slack.mentions.duration` - Mention processing time
   - `slack.slash_commands.duration` - Command processing time

2. **Error Rates**
   - `ollama.errors.rate` - AI model error rate
   - `slack.mentions.errors` - Mention error count
   - `slack.slash_commands.errors` - Command error count

3. **Usage Patterns**
   - `slack.mentions.total` - Total mentions
   - `slack.slash_commands.total` - Total commands
   - `slack.direct_messages.total` - Total DMs

4. **Performance**
   - `ollama.response.length` - Response quality indicator
   - `slack.context.messages_count` - Context richness

### Alerting Recommendations

1. **High Error Rate**: Alert when `ollama.errors.rate` > 0.1
2. **Slow Responses**: Alert when `ollama.response.duration` > 5 seconds
3. **Startup Failures**: Alert on `jamie.startup.failures` > 0
4. **High Memory Usage**: Monitor container memory usage

## 🔍 Debugging

### Local Development

Set `LOGFIRE_CONSOLE=true` for local development to see logs in console:

```bash
export LOGFIRE_CONSOLE=true
export LOGFIRE_SEND_TO_LOGFIRE=false
export ENVIRONMENT=development
```

### Log Levels

The application uses structured logging with different levels:
- **INFO**: Normal operations, successful requests
- **ERROR**: Errors and exceptions
- **SUCCESS**: Successful operations (via `log_success`)

### Span Attributes

Each span includes relevant attributes for debugging:
- Request/response lengths
- User IDs and channel information
- Processing durations
- Success/failure status
- Error details

## 🛠️ Customization

### Adding New Metrics

```python
# Record a custom metric
logfire.metric("custom.metric.name", value)

# Record a counter
logfire.metric("custom.counter", 1)
```

### Adding New Spans

```python
with logfire.span("custom.operation") as span:
    # Your code here
    span.set_attribute("custom_attr", "value")
```

### Custom Logging

```python
# Structured logging
logfire.info("Custom event", 
            custom_field="value",
            another_field=123)

# Error logging
log_error("Custom error",
         error=str(e),
         custom_context="value")
```

## 📚 Logfire Documentation

- [Logfire Python SDK](https://logfire.pydantic.dev/)
- [Logfire Dashboard](https://logfire.pydantic.dev/dashboard)
- [Metrics and Tracing](https://logfire.pydantic.dev/guides/metrics-and-tracing)

## 🎯 Benefits

1. **Observability**: Complete visibility into bot performance and usage
2. **Debugging**: Rich context for troubleshooting issues
3. **Performance**: Track response times and optimize bottlenecks
4. **Reliability**: Monitor error rates and system health
5. **Usage Analytics**: Understand how users interact with the bot
6. **Alerting**: Proactive monitoring and incident response

---

*This instrumentation provides comprehensive observability for the Jamie SRE Chatbot, enabling effective monitoring, debugging, and optimization.*
