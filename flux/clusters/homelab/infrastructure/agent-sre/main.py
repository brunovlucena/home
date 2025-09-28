#!/usr/bin/env python3
"""
SRE Agent Core
Main agent functionality for SRE tasks using LangChain and Ollama
"""

import os
import json
import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
from aiohttp import web, web_request
from aiohttp.web import Request, Response

# LangChain imports
from langchain_ollama import OllamaLLM
from langchain.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain.schema import HumanMessage, SystemMessage

# LangSmith imports for tracing
from langsmith import traceable
from langsmith.wrappers import wrap_openai

# Logfire imports
import logfire

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://192.168.0.12:11434")
MODEL_NAME = os.environ.get("MODEL_NAME", "bruno-sre:latest")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "sre-agent")

# Configure Logfire
sre_agent_token = os.getenv('LOGFIRE_TOKEN_SRE_AGENT')
if sre_agent_token:
    try:
        logfire.configure(service_name=SERVICE_NAME, token=sre_agent_token)
        logger.info("✅ Logfire configured successfully")
    except Exception as e:
        logger.warning(f"⚠️  Logfire configuration failed: {e}")
        logger.warning("⚠️  Continuing without Logfire...")
        # Disable Logfire to prevent crashes
        os.environ.pop('LOGFIRE_TOKEN_SRE_AGENT', None)
else:
    logger.warning("⚠️  LOGFIRE_TOKEN_SRE_AGENT not set, skipping Logfire configuration")

# Configure LangChain API key
langsmith_api_key = os.getenv('LANGSMITH_API_KEY')
if langsmith_api_key:
    os.environ['LANGCHAIN_API_KEY'] = langsmith_api_key
    logger.info("✅ LangSmith API key configured from environment")
else:
    logger.warning("⚠️  LANGSMITH_API_KEY not set, LangSmith features will be limited")

# Initialize Ollama LLM
try:
    llm = OllamaLLM(
        model=MODEL_NAME,
        base_url=OLLAMA_URL,
        temperature=0.7,
        top_p=0.9,
        num_ctx=4096,
        num_predict=1000
    )
    logger.info(f"✅ Ollama connection established: {OLLAMA_URL}")
except Exception as e:
    logger.error(f"❌ Error connecting to Ollama: {e}")
    llm = None

class SREAgent:
    """SRE Agent Core Class"""
    
    def __init__(self):
        self.llm = llm
        self.service_name = SERVICE_NAME
        
    @traceable(name="sre_chat", run_type="chain")
    @logfire.instrument("sre_chat")
    async def chat(self, message: str) -> str:
        """Handle general SRE chat requests"""
        if not self.llm:
            return "Error: Ollama connection not available"
        
        prompt = ChatPromptTemplate.from_template("""
        You are an SRE (Site Reliability Engineering) AI assistant. 
        You help with monitoring, troubleshooting, and maintaining system reliability.
        
        User question: {question}
        
        Please provide a helpful and accurate response based on SRE best practices.
        """)
        
        chain = prompt | self.llm
        response = chain.invoke({"question": message})
        return response
    
    @traceable(name="sre_analyze_logs", run_type="chain")
    @logfire.instrument("analyze_logs")
    async def analyze_logs(self, logs: str) -> str:
        """Analyze logs for SRE insights"""
        if not self.llm:
            return "Error: Ollama connection not available"
        
        prompt = ChatPromptTemplate.from_template("""
        As an SRE expert, analyze the following logs and provide insights:
        
        Logs:
        {logs}
        
        Please provide:
        1. Key issues identified
        2. Potential root causes
        3. Recommended actions
        4. Monitoring suggestions
        """)
        
        chain = prompt | self.llm
        analysis = chain.invoke({"logs": logs})
        return analysis
    
    @traceable(name="sre_incident_response", run_type="chain")
    @logfire.instrument("incident_response")
    async def incident_response(self, incident: str) -> str:
        """Provide incident response guidance"""
        if not self.llm:
            return "Error: Ollama connection not available"
        
        prompt = ChatPromptTemplate.from_template("""
        As an SRE expert, provide incident response guidance for the following situation:
        
        Incident: {incident}
        
        Please provide:
        1. Immediate actions to take
        2. Investigation steps
        3. Communication plan
        4. Post-incident actions
        5. Prevention measures
        """)
        
        chain = prompt | self.llm
        response = chain.invoke({"incident": incident})
        return response
    
    @traceable(name="sre_monitoring_advice", run_type="chain")
    @logfire.instrument("monitoring_advice")
    async def monitoring_advice(self, system: str) -> str:
        """Provide monitoring and alerting advice"""
        if not self.llm:
            return "Error: Ollama connection not available"
        
        prompt = ChatPromptTemplate.from_template("""
        As an SRE expert, provide monitoring and alerting advice for the following system:
        
        System: {system}
        
        Please provide:
        1. Key metrics to monitor
        2. Alert thresholds
        3. Dashboard recommendations
        4. Log analysis strategies
        5. Performance monitoring
        """)
        
        chain = prompt | self.llm
        advice = chain.invoke({"system": system})
        return advice
    
    @logfire.instrument("health_check")
    async def health_check(self) -> Dict[str, Any]:
        """Check agent health status"""
        return {
            "status": "healthy",
            "service": self.service_name,
            "timestamp": datetime.now().isoformat(),
            "ollama_url": OLLAMA_URL,
            "model_name": MODEL_NAME,
            "llm_connected": self.llm is not None
        }

# Global agent instance
agent = SREAgent()

async def health_handler(request: Request) -> Response:
    """Health check endpoint"""
    health_status = await agent.health_check()
    return web.json_response(health_status)

async def ready_handler(request: Request) -> Response:
    """Readiness check endpoint"""
    if agent.llm:
        return web.json_response({"status": "ready", "service": SERVICE_NAME})
    else:
        return web.json_response(
            {"status": "not_ready", "error": "Ollama connection not available"},
            status=503
        )

async def chat_handler(request: Request) -> Response:
    """Chat endpoint for SRE agent"""
    try:
        data = await request.json()
        message = data.get("message", "")
        
        if not message:
            return web.json_response(
                {"error": "Message is required"},
                status=400
            )
        
        response = await agent.chat(message)
        return web.json_response({
            "response": response,
            "service": SERVICE_NAME,
            "timestamp": datetime.now().isoformat()
        })
    
    except Exception as e:
        logger.error(f"Error in chat handler: {e}")
        return web.json_response(
            {"error": str(e)},
            status=500
        )

async def analyze_logs_handler(request: Request) -> Response:
    """Log analysis endpoint"""
    try:
        data = await request.json()
        logs = data.get("logs", "")
        
        if not logs:
            return web.json_response(
                {"error": "Logs are required"},
                status=400
            )
        
        analysis = await agent.analyze_logs(logs)
        return web.json_response({
            "analysis": analysis,
            "service": SERVICE_NAME,
            "timestamp": datetime.now().isoformat()
        })
    
    except Exception as e:
        logger.error(f"Error in analyze_logs handler: {e}")
        return web.json_response(
            {"error": str(e)},
            status=500
        )

async def incident_response_handler(request: Request) -> Response:
    """Incident response endpoint"""
    try:
        data = await request.json()
        incident = data.get("incident", "")
        
        if not incident:
            return web.json_response(
                {"error": "Incident description is required"},
                status=400
            )
        
        response = await agent.incident_response(incident)
        return web.json_response({
            "response": response,
            "service": SERVICE_NAME,
            "timestamp": datetime.now().isoformat()
        })
    
    except Exception as e:
        logger.error(f"Error in incident_response handler: {e}")
        return web.json_response(
            {"error": str(e)},
            status=500
        )

async def monitoring_advice_handler(request: Request) -> Response:
    """Monitoring advice endpoint"""
    try:
        data = await request.json()
        system = data.get("system", "")
        
        if not system:
            return web.json_response(
                {"error": "System description is required"},
                status=400
            )
        
        advice = await agent.monitoring_advice(system)
        return web.json_response({
            "advice": advice,
            "service": SERVICE_NAME,
            "timestamp": datetime.now().isoformat()
        })
    
    except Exception as e:
        logger.error(f"Error in monitoring_advice handler: {e}")
        return web.json_response(
            {"error": str(e)},
            status=500
        )

async def start_http_server():
    """Start the HTTP server"""
    app = web.Application()
    
    # Add routes
    app.router.add_get('/health', health_handler)
    app.router.add_get('/ready', ready_handler)
    app.router.add_post('/chat', chat_handler)
    app.router.add_post('/analyze-logs', analyze_logs_handler)
    app.router.add_post('/incident-response', incident_response_handler)
    app.router.add_post('/monitoring-advice', monitoring_advice_handler)
    
    # Start server
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    await site.start()
    
    logger.info("🌐 HTTP server started on port 8080")
    return runner

async def main():
    """Main function for running the agent"""
    logger.info(f"Starting {SERVICE_NAME} Agent")
    logger.info(f"Ollama URL: {OLLAMA_URL}")
    logger.info(f"Model: {MODEL_NAME}")
    
    # Test the agent
    if agent.llm:
        logger.info("✅ Agent initialized successfully")
        logger.info("Testing agent with sample question...")
        response = await agent.chat("How do I monitor Kubernetes pods?")
        logger.info(f"🤖 Agent Response: {response}")
    else:
        logger.error("❌ Agent not available - Ollama connection failed")
        return
    
    # Start HTTP server
    http_runner = await start_http_server()
    
    try:
        # Keep the server running
        logger.info("🏁 SRE Agent is running...")
        await asyncio.Event().wait()  # Run forever
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
    finally:
        await http_runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
