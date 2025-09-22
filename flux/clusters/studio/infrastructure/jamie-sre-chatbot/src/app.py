#!/usr/bin/env python3
"""
Jamie SRE Chatbot - Slack AI Bot
A specialized SRE chatbot using Slack Bolt for Python with Ollama integration.
Instrumented with Logfire for comprehensive observability.
"""

import os
import logging
import time
from datetime import datetime
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import requests
import json
from typing import Dict, Any, Optional
from flask import Flask, request, jsonify
import threading

# Logfire imports
import logfire

# Prometheus client for metrics endpoint
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST, Counter, Histogram, Gauge

# Configure logging first
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create a proper no-op span with all needed methods
class NoOpSpan:
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass
    def set_attribute(self, *args, **kwargs):
        pass

def noop(*args, **kwargs):
    pass

# Configure Logfire with Prometheus export
logfire_token = os.environ.get("LOGFIRE_TOKEN", "").strip()
prometheus_metrics_available = False

# Prometheus metrics definitions
ollama_requests_total = Counter('ollama_requests_total', 'Total number of Ollama requests', ['model', 'status'])
ollama_errors_total = Counter('ollama_errors_total', 'Total number of Ollama errors', ['error_type'])
ollama_response_duration = Histogram('ollama_response_duration_seconds', 'Ollama response duration in seconds', ['model'])
ollama_response_length = Histogram('ollama_response_length_bytes', 'Ollama response length in bytes', ['model'])

api_chat_requests_total = Counter('api_chat_requests_total', 'Total number of API chat requests', ['status'])
api_chat_requests_errors = Counter('api_chat_requests_errors', 'Total number of API chat errors')
api_chat_requests_duration = Histogram('api_chat_requests_duration_seconds', 'API chat request duration in seconds')
api_chat_requests_response_length = Histogram('api_chat_requests_response_length_bytes', 'API chat response length in bytes')

slack_mentions_total = Counter('slack_mentions_total', 'Total number of Slack mentions', ['status'])
slack_mentions_errors = Counter('slack_mentions_errors', 'Total number of Slack mention errors')
slack_mentions_duration = Histogram('slack_mentions_duration_seconds', 'Slack mention processing duration in seconds')
slack_mentions_response_length = Histogram('slack_mentions_response_length_bytes', 'Slack mention response length in bytes')

slack_slash_commands_total = Counter('slack_slash_commands_total', 'Total number of Slack slash commands', ['status'])
slack_slash_commands_errors = Counter('slack_slash_commands_errors', 'Total number of Slack slash command errors')
slack_slash_commands_duration = Histogram('slack_slash_commands_duration_seconds', 'Slack slash command processing duration in seconds')
slack_slash_commands_response_length = Histogram('slack_slash_commands_response_length_bytes', 'Slack slash command response length in bytes')

slack_direct_messages_total = Counter('slack_direct_messages_total', 'Total number of Slack direct messages', ['status'])
slack_direct_messages_errors = Counter('slack_direct_messages_errors', 'Total number of Slack direct message errors')
slack_direct_messages_duration = Histogram('slack_direct_messages_duration_seconds', 'Slack direct message processing duration in seconds')
slack_direct_messages_response_length = Histogram('slack_direct_messages_response_length_bytes', 'Slack direct message response length in bytes')

jamie_startup_attempts = Counter('jamie_startup_attempts_total', 'Total number of Jamie startup attempts')
jamie_startup_success = Counter('jamie_startup_success_total', 'Total number of successful Jamie startups')
jamie_startup_failures = Counter('jamie_startup_failures_total', 'Total number of failed Jamie startups')

if logfire_token:
    try:
        # Configure Logfire for observability
        logfire.configure(
            service_name="jamie-sre-chatbot",
            service_version="1.0.0",
            token=logfire_token,
            console=os.environ.get("LOGFIRE_CONSOLE", "false").lower() == "true",
            send_to_logfire=os.environ.get("LOGFIRE_SEND_TO_LOGFIRE", "true").lower() == "true"
        )
        logger.info("Logfire configured successfully")
        prometheus_metrics_available = True
    except Exception as e:
        logger.error(f"Failed to configure Logfire: {e}")
        # Disable logfire by replacing with no-op functions
        logfire.info = noop
        logfire.error = noop
        logfire.span = lambda *args, **kwargs: NoOpSpan()
        logfire.metric_counter = lambda *args, **kwargs: type('counter', (), {'add': noop})()
        logfire.metric_histogram = lambda *args, **kwargs: type('histogram', (), {'record': noop})()
else:
    logger.info("No Logfire token provided, disabling Logfire")
    # Disable logfire by replacing with no-op functions
    logfire.info = noop
    logfire.error = noop
    logfire.span = lambda *args, **kwargs: NoOpSpan()
    logfire.metric_counter = lambda *args, **kwargs: type('counter', (), {'add': noop})()
    logfire.metric_histogram = lambda *args, **kwargs: type('histogram', (), {'record': noop})()

# Logfire already provides OpenTelemetry metrics under the hood
# We just need to expose them via a Prometheus endpoint

# Initialize the Slack app
app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)

# Ollama configuration
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://192.168.0.3:11434")
MODEL_NAME = os.environ.get("MODEL_NAME", "bruno-sre")

class OllamaClient:
    """Client for interacting with Ollama API with Logfire instrumentation"""
    
    def __init__(self, base_url: str, model_name: str):
        self.base_url = base_url
        self.model_name = model_name
        logfire.info("OllamaClient initialized", 
                    base_url=base_url, 
                    model_name=model_name)
    
    def generate_response(self, prompt: str, context: str = "") -> str:
        """Generate a response using the Ollama model with comprehensive logging"""
        start_time = time.time()
        
        with logfire.span("ollama.generate_response") as span:
            try:
                # Prepare the full prompt with context
                full_prompt = f"{context}\n\nUser: {prompt}\nAssistant:"
                
                payload = {
                    "model": self.model_name,
                    "prompt": full_prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.9,
                        "max_tokens": 1000
                    }
                }
                
                # Log the request
                logfire.info("Sending request to Ollama", 
                           model=self.model_name,
                           prompt_preview=prompt[:100] + "..." if len(prompt) > 100 else prompt,
                           context_preview=context[:100] + "..." if len(context) > 100 else context)
                
                response = requests.post(
                    f"{self.base_url}/api/generate",
                    json=payload,
                    timeout=30
                )
                response.raise_for_status()
                
                result = response.json()
                response_text = result.get("response", "I'm sorry, I couldn't generate a response.")
                
                # Calculate metrics
                duration = time.time() - start_time
                response_length = len(response_text)
                
                # Log success metrics
                logfire.info("Ollama response generated successfully",
                           duration_ms=round(duration * 1000, 2),
                           response_length=response_length,
                           model=self.model_name)
                
                # Record metrics (both Logfire and Prometheus)
                logfire.metric_histogram("ollama.response.duration").record(duration)
                logfire.metric_histogram("ollama.response.length").record(response_length)
                logfire.metric_counter("ollama.requests.total").add(1)
                
                # Record Prometheus metrics
                ollama_requests_total.labels(model=self.model_name, status='success').inc()
                ollama_response_duration.labels(model=self.model_name).observe(duration)
                ollama_response_length.labels(model=self.model_name).observe(response_length)
                
                span.set_attribute("response_length", response_length)
                span.set_attribute("duration_ms", round(duration * 1000, 2))
                span.set_attribute("success", True)
                
                return response_text
                
            except requests.exceptions.RequestException as e:
                duration = time.time() - start_time
                error_msg = f"Ollama API error: {e}"
                
                logfire.error("Ollama API request failed",
                             error=str(e),
                             error_type=type(e).__name__,
                             duration_ms=round(duration * 1000, 2),
                             model=self.model_name)
                
                # Record error metrics (both Logfire and Prometheus)
                logfire.metric_counter("ollama.errors.total").add(1)
                logfire.metric_counter("ollama.errors.rate").add(1)
                
                # Record Prometheus metrics
                ollama_requests_total.labels(model=self.model_name, status='error').inc()
                ollama_errors_total.labels(error_type=type(e).__name__).inc()
                
                span.set_attribute("error", str(e))
                span.set_attribute("error_type", type(e).__name__)
                span.set_attribute("success", False)
                
                return "I'm having trouble connecting to my AI model. Please try again later."
                
            except Exception as e:
                duration = time.time() - start_time
                error_msg = f"Unexpected error: {e}"
                
                logfire.error("Unexpected error in Ollama client",
                         error=str(e),
                         error_type=type(e).__name__,
                         duration_ms=round(duration * 1000, 2),
                         model=self.model_name)
                
                # Record error metrics (both Logfire and Prometheus)
                logfire.metric_counter("ollama.errors.total").add(1)
                logfire.metric_counter("ollama.errors.rate").add(1)
                
                # Record Prometheus metrics
                ollama_requests_total.labels(model=self.model_name, status='error').inc()
                ollama_errors_total.labels(error_type=type(e).__name__).inc()
                
                span.set_attribute("error", str(e))
                span.set_attribute("error_type", type(e).__name__)
                span.set_attribute("success", False)
                
                return "An unexpected error occurred. Please try again."

# Initialize Ollama client
ollama_client = OllamaClient(OLLAMA_URL, MODEL_NAME)

# Initialize Flask API server for bruno-site integration
api_app = Flask(__name__)
# Logfire automatically instruments Flask and Requests when configured

@api_app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Kubernetes"""
    return jsonify({
        "status": "healthy",
        "service": "jamie-sre-chatbot",
        "timestamp": datetime.now().isoformat(),
        "ollama_url": OLLAMA_URL,
        "model_name": MODEL_NAME
    })

@api_app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Prometheus metrics endpoint using Logfire's built-in OpenTelemetry metrics"""
    if not prometheus_metrics_available:
        return "Metrics not available - Logfire not configured", 503
    
    try:
        # Collect all Prometheus metrics
        metrics_data = generate_latest()
        return metrics_data, 200, {'Content-Type': CONTENT_TYPE_LATEST}
    except Exception as e:
        logger.error(f"Error collecting metrics: {e}")
        return f"Error collecting metrics: {e}", 500

@api_app.route('/chat', methods=['POST'])
def chat_endpoint():
    """Chat endpoint for bruno-site integration"""
    start_time = time.time()
    
    with logfire.span("api.chat_endpoint") as span:
        try:
            data = request.get_json()
            if not data or 'message' not in data:
                return jsonify({"error": "Message is required"}), 400
            
            message = data['message'].strip()
            context = data.get('context', '')
            conversation_id = data.get('conversation_id', '')
            
            logfire.info("Processing API chat request",
                        message_preview=message[:100] + "..." if len(message) > 100 else message,
                        context_preview=context[:100] + "..." if len(context) > 100 else context,
                        conversation_id=conversation_id)
            
            if not message:
                return jsonify({"error": "Message cannot be empty"}), 400
            
            # Get response from Ollama
            response = ollama_client.generate_response(message, context)
            
            # Calculate metrics
            duration = time.time() - start_time
            
            # Log success
            logfire.info("API chat request processed successfully",
                       message_length=len(message),
                       response_length=len(response),
                       duration_ms=round(duration * 1000, 2),
                       conversation_id=conversation_id)
            
            # Record metrics (Logfire handles OpenTelemetry export automatically)
            logfire.metric_counter("api.chat_requests.total").add(1)
            logfire.metric_histogram("api.chat_requests.duration").record(duration)
            logfire.metric_histogram("api.chat_requests.response_length").record(len(response))
            
            span.set_attribute("message_length", len(message))
            span.set_attribute("response_length", len(response))
            span.set_attribute("duration_ms", round(duration * 1000, 2))
            span.set_attribute("conversation_id", conversation_id)
            span.set_attribute("success", True)
            
            return jsonify({
                "response": response,
                "model": MODEL_NAME,
                "timestamp": datetime.now().isoformat(),
                "processing_time": duration,
                "conversation_id": conversation_id
            })
            
        except Exception as e:
            duration = time.time() - start_time
            
            logfire.error("Error processing API chat request",
                         error=str(e),
                         error_type=type(e).__name__,
                         duration_ms=round(duration * 1000, 2))
            
            # Record error metrics
            logfire.metric_counter("api.chat_requests.errors").add(1)
            logfire.metric_counter("api.chat_requests.error_rate").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)
            
            return jsonify({"error": "Internal server error"}), 500

def start_api_server():
    """Start the Flask API server in a separate thread"""
    try:
        logfire.info("Starting Jamie API server", port=8080)
        api_app.run(host='0.0.0.0', port=8080, debug=False, use_reloader=False)
    except Exception as e:
        logfire.error("Failed to start API server", error=str(e))
        logger.error(f"Failed to start API server: {e}")

def start_metrics_server():
    """Start a separate metrics server on port 9090"""
    try:
        from flask import Flask
        metrics_app = Flask(__name__)
        
        @metrics_app.route('/metrics')
        def metrics():
            """Prometheus metrics endpoint using Logfire's built-in metrics"""
            if not prometheus_metrics_available:
                return "Metrics not available - Logfire not configured", 503
            
            try:
                # Collect all Prometheus metrics
                metrics_data = generate_latest()
                return metrics_data, 200, {'Content-Type': CONTENT_TYPE_LATEST}
            except Exception as e:
                logger.error(f"Error collecting metrics: {e}")
                return f"Error collecting metrics: {e}", 500
        
        @metrics_app.route('/health')
        def health():
            """Health check for metrics server"""
            return "OK", 200
        
        logfire.info("Starting metrics server", port=9090)
        metrics_app.run(host='0.0.0.0', port=9090, debug=False, use_reloader=False)
    except Exception as e:
        logfire.error("Failed to start metrics server", error=str(e))
        logger.error(f"Failed to start metrics server: {e}")

@app.event("app_mention")
def handle_mention(event, say):
    """Handle when the bot is mentioned in a channel with Logfire instrumentation"""
    start_time = time.time()
    
    with logfire.span("slack.handle_mention") as span:
        try:
            user_id = event.get("user")
            text = event.get("text", "")
            channel = event.get("channel")
            
            logfire.info("Processing app mention",
                        user_id=user_id,
                        channel=channel,
                        text_preview=text[:100] + "..." if len(text) > 100 else text)
            
            # Extract the actual question (remove the mention)
            question = text.replace(f"<@{app.client.auth_test()['user_id']}>", "").strip()
            
            if not question:
                logfire.info("Empty question received, sending welcome message")
                say("Hello! I'm Jamie, your SRE assistant. Ask me anything about Site Reliability Engineering, monitoring, incident response, or Bruno's technical background!")
                
                # Record metrics
                logfire.metric_counter("slack.mentions.empty").add(1)
                span.set_attribute("question_empty", True)
                span.set_attribute("success", True)
                return
            
            # Generate context based on channel
            context = get_channel_context(channel)
            
            # Get response from Ollama
            response = ollama_client.generate_response(question, context)
            
            # Send response
            say(f"🤖 *Jamie SRE Assistant*\n\n{response}")
            
            # Calculate metrics
            duration = time.time() - start_time
            
            # Log success
            logfire.info("App mention handled successfully",
                       user_id=user_id,
                       channel=channel,
                       question_length=len(question),
                       response_length=len(response),
                       duration_ms=round(duration * 1000, 2))
            
            # Record metrics (Logfire handles OpenTelemetry export automatically)
            logfire.metric_counter("slack.mentions.total").add(1)
            logfire.metric_histogram("slack.mentions.duration").record(duration)
            logfire.metric_histogram("slack.mentions.response_length").record(len(response))
            
            span.set_attribute("question_length", len(question))
            span.set_attribute("response_length", len(response))
            span.set_attribute("duration_ms", round(duration * 1000, 2))
            span.set_attribute("success", True)
            
        except Exception as e:
            duration = time.time() - start_time
            
            logfire.error("Error handling app mention",
                     error=str(e),
                     error_type=type(e).__name__,
                     user_id=user_id,
                     channel=channel,
                     duration_ms=round(duration * 1000, 2))
            
            # Record error metrics
            logfire.metric_counter("slack.mentions.errors").add(1)
            logfire.metric_counter("slack.mentions.error_rate").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)
            
            say("Sorry, I encountered an error processing your request. Please try again.")

@app.command("/ask-jamie")
def handle_ask_jamie_command(ack, respond, command):
    """Handle the /ask-jamie slash command with Logfire instrumentation"""
    start_time = time.time()
    ack()
    
    with logfire.span("slack.handle_slash_command") as span:
        try:
            question = command.get("text", "").strip()
            user_id = command.get("user_id")
            channel_id = command.get("channel_id")
            
            logfire.info("Processing slash command",
                        user_id=user_id,
                        channel_id=channel_id,
                        question_preview=question[:100] + "..." if len(question) > 100 else question)
            
            if not question:
                logfire.info("Empty question in slash command, sending usage message")
                respond("Please provide a question! Usage: `/ask-jamie What is SRE?`")
                
                # Record metrics
                logfire.metric_counter("slack.slash_commands.empty").add(1)
                span.set_attribute("question_empty", True)
                span.set_attribute("success", True)
                return
            
            # Generate context
            context = get_channel_context(channel_id)
            
            # Get response from Ollama
            response = ollama_client.generate_response(question, context)
            
            # Send response
            respond(f"🤖 *Jamie SRE Assistant*\n\n{response}")
            
            # Calculate metrics
            duration = time.time() - start_time
            
            # Log success
            logfire.info("Slash command handled successfully",
                       user_id=user_id,
                       channel_id=channel_id,
                       question_length=len(question),
                       response_length=len(response),
                       duration_ms=round(duration * 1000, 2))
            
            # Record metrics (Logfire handles OpenTelemetry export automatically)
            logfire.metric_counter("slack.slash_commands.total").add(1)
            logfire.metric_histogram("slack.slash_commands.duration").record(duration)
            logfire.metric_histogram("slack.slash_commands.response_length").record(len(response))
            
            span.set_attribute("question_length", len(question))
            span.set_attribute("response_length", len(response))
            span.set_attribute("duration_ms", round(duration * 1000, 2))
            span.set_attribute("success", True)
            
        except Exception as e:
            duration = time.time() - start_time
            
            logfire.error("Error handling slash command",
                     error=str(e),
                     error_type=type(e).__name__,
                     user_id=command.get("user_id"),
                     channel_id=command.get("channel_id"),
                     duration_ms=round(duration * 1000, 2))
            
            # Record error metrics
            logfire.metric_counter("slack.slash_commands.errors").add(1)
            logfire.metric_counter("slack.slash_commands.error_rate").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)
            
            respond("Sorry, I encountered an error processing your request. Please try again.")

@app.event("message")
def handle_message_events(event, say):
    """Handle direct messages to the bot with Logfire instrumentation"""
    start_time = time.time()
    
    with logfire.span("slack.handle_direct_message") as span:
        try:
            # Only respond to direct messages (not channel messages)
            if event.get("channel_type") != "im":
                span.set_attribute("ignored", True)
                span.set_attribute("reason", "not_direct_message")
                return
            
            user_id = event.get("user")
            text = event.get("text", "")
            
            logfire.info("Processing direct message",
                        user_id=user_id,
                        text_preview=text[:100] + "..." if len(text) > 100 else text)
            
            if not text:
                span.set_attribute("ignored", True)
                span.set_attribute("reason", "empty_message")
                return
            
            # Generate context for DM
            context = get_dm_context(user_id)
            
            # Get response from Ollama
            response = ollama_client.generate_response(text, context)
            
            # Send response
            say(f"🤖 *Jamie SRE Assistant*\n\n{response}")
            
            # Calculate metrics
            duration = time.time() - start_time
            
            # Log success
            logfire.info("Direct message handled successfully",
                       user_id=user_id,
                       message_length=len(text),
                       response_length=len(response),
                       duration_ms=round(duration * 1000, 2))
            
            # Record metrics (Logfire handles OpenTelemetry export automatically)
            logfire.metric_counter("slack.direct_messages.total").add(1)
            logfire.metric_histogram("slack.direct_messages.duration").record(duration)
            logfire.metric_histogram("slack.direct_messages.response_length").record(len(response))
            
            span.set_attribute("message_length", len(text))
            span.set_attribute("response_length", len(response))
            span.set_attribute("duration_ms", round(duration * 1000, 2))
            span.set_attribute("success", True)
            
        except Exception as e:
            duration = time.time() - start_time
            
            logfire.error("Error handling direct message",
                     error=str(e),
                     error_type=type(e).__name__,
                     user_id=event.get("user"),
                     duration_ms=round(duration * 1000, 2))
            
            # Record error metrics
            logfire.metric_counter("slack.direct_messages.errors").add(1)
            logfire.metric_counter("slack.direct_messages.error_rate").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)

def get_channel_context(channel_id: str) -> str:
    """Get context about the current channel with Logfire instrumentation"""
    with logfire.span("slack.get_channel_context") as span:
        try:
            # Get channel info
            channel_info = app.client.conversations_info(channel=channel_id)
            channel_name = channel_info["channel"]["name"]
            
            # Get recent messages for context
            history = app.client.conversations_history(
                channel=channel_id,
                limit=5
            )
            
            recent_messages = []
            for msg in history.get("messages", []):
                if msg.get("text") and not msg.get("bot_id"):
                    recent_messages.append(msg["text"][:100])  # Truncate long messages
            
            context = f"Channel: #{channel_name}\n"
            if recent_messages:
                context += f"Recent conversation context: {' | '.join(recent_messages)}\n"
            
            logfire.info("Channel context retrieved successfully",
                        channel_id=channel_id,
                        channel_name=channel_name,
                        recent_messages_count=len(recent_messages),
                        context_length=len(context))
            
            # Record metrics
            logfire.metric_counter("slack.context.channel_requests").add(1)
            logfire.metric_histogram("slack.context.messages_count").record(len(recent_messages))
            
            span.set_attribute("channel_name", channel_name)
            span.set_attribute("recent_messages_count", len(recent_messages))
            span.set_attribute("context_length", len(context))
            span.set_attribute("success", True)
            
            return context
            
        except SlackApiError as e:
            logfire.error("Error getting channel context",
                     error=str(e),
                     error_type=type(e).__name__,
                     channel_id=channel_id)
            
            # Record error metrics
            logfire.metric_counter("slack.context.errors").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)
            
            return ""

def get_dm_context(user_id: str) -> str:
    """Get context for direct message with Logfire instrumentation"""
    with logfire.span("slack.get_dm_context") as span:
        try:
            # Get user info
            user_info = app.client.users_info(user=user_id)
            user_name = user_info["user"]["real_name"]
            
            context = f"Direct message with {user_name}\n"
            
            logfire.info("DM context retrieved successfully",
                        user_id=user_id,
                        user_name=user_name,
                        context_length=len(context))
            
            # Record metrics
            logfire.metric_counter("slack.context.dm_requests").add(1)
            
            span.set_attribute("user_name", user_name)
            span.set_attribute("context_length", len(context))
            span.set_attribute("success", True)
            
            return context
            
        except SlackApiError as e:
            logfire.error("Error getting DM context",
                     error=str(e),
                     error_type=type(e).__name__,
                     user_id=user_id)
            
            # Record error metrics
            logfire.metric_counter("slack.context.dm_errors").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)
            
            return ""

@app.event("app_home_opened")
def handle_app_home_opened(client, event, logger):
    """Handle when user opens the app home with Logfire instrumentation"""
    with logfire.span("slack.handle_app_home_opened") as span:
        try:
            user_id = event["user"]
            
            logfire.info("App home opened",
                        user_id=user_id)
            
            # Publish a home view
            client.views_publish(
                user_id=user_id,
                view={
                    "type": "home",
                    "blocks": [
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": "*Welcome to Jamie SRE Assistant!* 🤖\n\nI'm your specialized Site Reliability Engineering assistant, trained on Bruno Lucena's SRE knowledge and best practices.\n\n*What I can help with:*\n• SRE principles and practices\n• SLIs, SLOs, and error budgets\n• Monitoring and alerting strategies\n• Incident response procedures\n• Capacity planning and chaos engineering\n• Microservices architecture patterns\n• Bruno's technical background and preferences"
                            }
                        },
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": "*How to use me:*\n• Mention me in any channel: `@Jamie`\n• Use the slash command: `/ask-jamie`\n• Send me a direct message\n• Ask me anything about SRE!"
                            }
                        },
                        {
                            "type": "divider"
                        },
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": "*Example questions:*\n• What is Site Reliability Engineering?\n• How do you calculate SLIs and SLOs?\n• Tell me about Bruno Lucena\n• How do you troubleshoot high error rates?\n• What are the key principles of SRE?\n• How do you implement canary deployments?"
                            }
                        }
                    ]
                }
            )
            
            # Record metrics
            logfire.metric_counter("slack.app_home.opens").add(1)
            
            span.set_attribute("user_id", user_id)
            span.set_attribute("success", True)
            
            logfire.info("App home view published successfully",
                       user_id=user_id)
            
        except Exception as e:
            logfire.error("Error publishing home view",
                     error=str(e),
                     error_type=type(e).__name__,
                     user_id=event.get("user"))
            
            # Record error metrics
            logfire.metric_counter("slack.app_home.errors").add(1)
            
            span.set_attribute("error", str(e))
            span.set_attribute("error_type", type(e).__name__)
            span.set_attribute("success", False)


if __name__ == "__main__":
    # Log application startup
    logfire.info("Jamie SRE Chatbot starting up",
                environment=os.environ.get("ENVIRONMENT", "development"),
                ollama_url=os.environ.get("OLLAMA_URL", "http://192.168.0.3:11434"),
                model_name=os.environ.get("MODEL_NAME", "bruno-sre"))
    
    # Validate required environment variables
    required_vars = ["SLACK_BOT_TOKEN", "SLACK_SIGNING_SECRET", "SLACK_APP_TOKEN"]
    missing_vars = [var for var in required_vars if not os.environ.get(var)]
    
    if missing_vars:
        logfire.error("Missing required environment variables",
                 missing_vars=missing_vars)
        logger.error(f"Missing required environment variables: {missing_vars}")
        exit(1)
    
    # Record startup metrics
    logfire.metric_counter("jamie.startup.attempts").add(1)
    logfire.metric_histogram("jamie.startup.timestamp").record(time.time())
    
    try:
        # Start the API server in a separate thread
        api_thread = threading.Thread(target=start_api_server, daemon=True)
        api_thread.start()
        
        # Start the metrics server in a separate thread
        metrics_thread = threading.Thread(target=start_metrics_server, daemon=True)
        metrics_thread.start()
        
        # Start the Slack app
        handler = SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"])
        
        logfire.info("Jamie SRE Chatbot started successfully",
                   environment=os.environ.get("ENVIRONMENT", "development"),
                   ollama_url=os.environ.get("OLLAMA_URL", "http://192.168.0.3:11434"),
                   model_name=os.environ.get("MODEL_NAME", "bruno-sre"))
        
        logger.info("🤖 Jamie SRE Chatbot is starting...")
        logger.info("🌐 API server started on port 8080")
        logger.info("📊 Metrics server started on port 9090")
        
        # Record successful startup
        logfire.metric_counter("jamie.startup.success").add(1)
        
        handler.start()
        
    except Exception as e:
        logfire.error("Failed to start Jamie SRE Chatbot",
                 error=str(e),
                 error_type=type(e).__name__)
        
        # Record startup failure
        logfire.metric_counter("jamie.startup.failures").add(1)
        
        logger.error(f"Failed to start Jamie SRE Chatbot: {e}")
        exit(1)
