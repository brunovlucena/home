#!/usr/bin/env python3
"""
LangGraph Agent for Kubernetes
A modern AI agent using LangGraph that connects to Ollama for log analysis
"""

import os
import logging
import asyncio
import threading
import time
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import json
import requests
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

# LangGraph imports
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_community.llms import Ollama
from langchain_core.tools import tool

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="LangGraph Agent",
    description="AI Agent for log analysis using LangGraph and Ollama",
    version="1.0.0"
)

# Configuration
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://ollama-service:11434")
MODEL_NAME = os.environ.get("MODEL_NAME", "gemma3n:e4b")
LOKI_MCP_URL = os.environ.get("LOKI_MCP_URL", "http://loki-mcp-server.loki:8080")
AGENT_PORT = int(os.environ.get("AGENT_PORT", "8080"))

# Proactive monitoring configuration
MONITORING_ENABLED = os.environ.get("MONITORING_ENABLED", "true").lower() == "true"
MONITORING_INTERVAL = int(os.environ.get("MONITORING_INTERVAL", "300"))  # 5 minutes
ALERT_THRESHOLD = int(os.environ.get("ALERT_THRESHOLD", "10"))  # Alert if >10 errors

# Initialize Ollama LLM with Gemma 3n:e4b
llm = Ollama(
    base_url=OLLAMA_URL,
    model=MODEL_NAME,
    temperature=0.7,
    top_p=0.9,
    num_ctx=4096,    # Context window for Gemma 3n
    num_predict=1000 # Prediction limit
)

# Define tools for the agent
@tool
def query_loki_logs(query: str, limit: int = 100) -> str:
    """Query Loki logs via MCP server for analysis"""
    try:
        # Query Loki MCP server using the correct MCP protocol
        response = requests.post(
            f"{LOKI_MCP_URL}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "loki_query",
                    "arguments": {
                        "query": query,
                        "limit": limit,
                        "start": "1h",  # Last hour
                        "end": "now"
                    }
                }
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        if "result" in data and "content" in data["result"]:
            logs = data["result"]["content"]
            return f"Found {len(logs)} logs matching query '{query}':\n" + "\n".join(logs[:10])
        else:
            return f"No logs found for query '{query}'"
            
    except Exception as e:
        logger.error(f"Error querying Loki MCP: {e}")
        return f"Error querying logs via MCP: {str(e)}"

@tool
def analyze_test_failures() -> str:
    """Analyze test failures from the test infrastructure via MCP"""
    try:
        # Query for test-related logs via MCP
        test_query = '{namespace="mocks"} |= "test" |= "failed"'
        response = requests.post(
            f"{LOKI_MCP_URL}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": "loki_query",
                    "arguments": {
                        "query": test_query,
                        "limit": 50,
                        "start": "1h",
                        "end": "now"
                    }
                }
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        if "result" in data and "content" in data["result"]:
            failures = [log for log in data["result"]["content"] if "failed" in log.lower()]
            
            if failures:
                return f"Found {len(failures)} test failures:\n" + "\n".join(failures[:5])
            else:
                return "No test failures found in the last hour"
        else:
            return "No test data available"
            
    except Exception as e:
        logger.error(f"Error analyzing test failures via MCP: {e}")
        return f"Error analyzing tests via MCP: {str(e)}"

@tool
def get_system_health() -> str:
    """Get overall system health status via MCP"""
    try:
        # Query for error logs across all namespaces via MCP
        error_query = '{namespace=~".+"} |= "ERROR" |= "error"'
        response = requests.post(
            f"{LOKI_MCP_URL}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {
                    "name": "loki_query",
                    "arguments": {
                        "query": error_query,
                        "limit": 20,
                        "start": "30m",
                        "end": "now"
                    }
                }
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        if "result" in data and "content" in data["result"]:
            errors = data["result"]["content"]
            
            if errors:
                return f"System has {len(errors)} errors in the last 30 minutes:\n" + "\n".join(errors[:3])
            else:
                return "System is healthy - no errors found in the last 30 minutes"
        else:
            return "Unable to determine system health"
            
    except Exception as e:
        logger.error(f"Error getting system health via MCP: {e}")
        return f"Error checking system health via MCP: {str(e)}"

# Define the agent state
class AgentState:
    def __init__(self):
        self.messages = []
        self.context = {}
        self.tools_used = []
        self.results = {}
        self.last_monitoring = None
        self.alerts = []

# Global monitoring state
monitoring_state = {
    "last_check": None,
    "error_count": 0,
    "alerts": [],
    "is_monitoring": False
}

# Proactive monitoring functions
def check_system_health_proactive() -> Dict[str, Any]:
    """Proactive system health check"""
    try:
        # Query for errors in the last 5 minutes
        error_query = '{namespace=~".+"} |= "ERROR" |= "error"'
        response = requests.post(
            f"{LOKI_MCP_URL}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 999,
                "method": "tools/call",
                "params": {
                    "name": "loki_query",
                    "arguments": {
                        "query": error_query,
                        "limit": 100,
                        "start": "5m",
                        "end": "now"
                    }
                }
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        if "result" in data and "content" in data["result"]:
            errors = data["result"]["content"]
            return {
                "error_count": len(errors),
                "errors": errors[:5],  # First 5 errors
                "timestamp": datetime.now().isoformat(),
                "status": "healthy" if len(errors) < ALERT_THRESHOLD else "unhealthy"
            }
        else:
            return {
                "error_count": 0,
                "errors": [],
                "timestamp": datetime.now().isoformat(),
                "status": "unknown"
            }
            
    except Exception as e:
        logger.error(f"Error in proactive health check: {e}")
        return {
            "error_count": -1,
            "errors": [],
            "timestamp": datetime.now().isoformat(),
            "status": "error",
            "error": str(e)
        }

def check_test_failures_proactive() -> Dict[str, Any]:
    """Proactive test failure check"""
    try:
        # Query for test failures in the last 10 minutes
        test_query = '{namespace="mocks"} |= "test" |= "failed"'
        response = requests.post(
            f"{LOKI_MCP_URL}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 998,
                "method": "tools/call",
                "params": {
                    "name": "loki_query",
                    "arguments": {
                        "query": test_query,
                        "limit": 50,
                        "start": "10m",
                        "end": "now"
                    }
                }
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        if "result" in data and "content" in data["result"]:
            failures = [log for log in data["result"]["content"] if "failed" in log.lower()]
            return {
                "failure_count": len(failures),
                "failures": failures[:3],  # First 3 failures
                "timestamp": datetime.now().isoformat(),
                "status": "healthy" if len(failures) == 0 else "unhealthy"
            }
        else:
            return {
                "failure_count": 0,
                "failures": [],
                "timestamp": datetime.now().isoformat(),
                "status": "healthy"
            }
            
    except Exception as e:
        logger.error(f"Error in proactive test check: {e}")
        return {
            "failure_count": -1,
            "failures": [],
            "timestamp": datetime.now().isoformat(),
            "status": "error",
            "error": str(e)
        }

def generate_ai_insights(health_data: Dict[str, Any], test_data: Dict[str, Any]) -> str:
    """Generate AI insights from monitoring data"""
    try:
        # Create context for AI analysis
        context = f"""
        System Health Analysis:
        - Error count: {health_data.get('error_count', 0)}
        - System status: {health_data.get('status', 'unknown')}
        - Recent errors: {health_data.get('errors', [])}
        
        Test Health Analysis:
        - Test failure count: {test_data.get('failure_count', 0)}
        - Test status: {test_data.get('status', 'unknown')}
        - Recent failures: {test_data.get('failures', [])}
        
        Please provide insights and recommendations based on this data.
        """
        
        # Get AI analysis
        response = llm.invoke(context)
        return response
        
    except Exception as e:
        logger.error(f"Error generating AI insights: {e}")
        return f"Unable to generate insights: {str(e)}"

def monitoring_worker():
    """Background monitoring worker"""
    global monitoring_state
    
    while monitoring_state["is_monitoring"]:
        try:
            logger.info("Running proactive monitoring check...")
            
            # Check system health
            health_data = check_system_health_proactive()
            test_data = check_test_failures_proactive()
            
            # Update monitoring state
            monitoring_state["last_check"] = datetime.now().isoformat()
            monitoring_state["error_count"] = health_data.get("error_count", 0)
            
            # Generate alerts if needed
            alerts = []
            if health_data.get("error_count", 0) >= ALERT_THRESHOLD:
                alerts.append({
                    "type": "system_health",
                    "severity": "high",
                    "message": f"High error count: {health_data.get('error_count', 0)} errors",
                    "timestamp": datetime.now().isoformat()
                })
            
            if test_data.get("failure_count", 0) > 0:
                alerts.append({
                    "type": "test_failures",
                    "severity": "medium",
                    "message": f"Test failures detected: {test_data.get('failure_count', 0)} failures",
                    "timestamp": datetime.now().isoformat()
                })
            
            monitoring_state["alerts"] = alerts
            
            # Generate AI insights if there are issues
            if alerts or health_data.get("error_count", 0) > 0 or test_data.get("failure_count", 0) > 0:
                insights = generate_ai_insights(health_data, test_data)
                logger.info(f"AI Insights: {insights}")
            
            logger.info(f"Monitoring check completed. Errors: {health_data.get('error_count', 0)}, Test failures: {test_data.get('failure_count', 0)}")
            
        except Exception as e:
            logger.error(f"Error in monitoring worker: {e}")
        
        # Wait for next check
        time.sleep(MONITORING_INTERVAL)

def start_monitoring():
    """Start the monitoring worker"""
    global monitoring_state
    
    if MONITORING_ENABLED and not monitoring_state["is_monitoring"]:
        monitoring_state["is_monitoring"] = True
        monitoring_thread = threading.Thread(target=monitoring_worker, daemon=True)
        monitoring_thread.start()
        logger.info(f"Started proactive monitoring (interval: {MONITORING_INTERVAL}s)")

def stop_monitoring():
    """Stop the monitoring worker"""
    global monitoring_state
    monitoring_state["is_monitoring"] = False
    logger.info("Stopped proactive monitoring")

# Define the agent workflow
def create_agent_graph():
    """Create the LangGraph agent workflow"""
    
    # Define the state
    def agent_node(state: AgentState) -> Dict[str, Any]:
        """Main agent reasoning node"""
        try:
            # Get the latest user message
            if not state.messages:
                return {"messages": [AIMessage(content="Hello! I'm your log analysis agent. How can I help you?")]}
            
            last_message = state.messages[-1]
            
            # Create context for the LLM
            context = f"""
            You are an AI agent specialized in log analysis and system monitoring.
            You have access to Loki logs and can analyze test failures, system health, and more.
            
            Current context: {state.context}
            Tools available: query_loki_logs, analyze_test_failures, get_system_health
            
            User request: {last_message.content}
            
            Provide a helpful response and suggest which tools to use if needed.
            """
            
            # Get response from Ollama
            response = llm.invoke(context)
            
            return {
                "messages": [AIMessage(content=response)],
                "context": {"last_response": response}
            }
            
        except Exception as e:
            logger.error(f"Error in agent node: {e}")
            return {
                "messages": [AIMessage(content=f"Sorry, I encountered an error: {str(e)}")]
            }
    
    # Create the graph
    workflow = StateGraph(AgentState)
    
    # Add nodes
    workflow.add_node("agent", agent_node)
    workflow.add_node("tools", ToolNode([query_loki_logs, analyze_test_failures, get_system_health]))
    
    # Add edges
    workflow.add_edge("agent", "tools")
    workflow.add_edge("tools", END)
    
    # Set entry point
    workflow.set_entry_point("agent")
    
    return workflow.compile()

# Initialize the agent
agent = create_agent_graph()

# FastAPI endpoints
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "langgraph-agent",
        "timestamp": datetime.now().isoformat(),
        "ollama_url": OLLAMA_URL,
        "model_name": MODEL_NAME,
        "loki_mcp_url": LOKI_MCP_URL
    }

@app.get("/metrics")
async def metrics():
    """Metrics endpoint"""
    return {
        "agent_requests_total": 0,
        "agent_errors_total": 0,
        "ollama_connection": "connected" if OLLAMA_URL else "disconnected"
    }

@app.post("/chat")
async def chat_endpoint(request: Dict[str, Any]):
    """Main chat endpoint for the agent"""
    try:
        message = request.get("message", "")
        if not message:
            raise HTTPException(status_code=400, detail="Message is required")
        
        # Create initial state
        state = AgentState()
        state.messages = [HumanMessage(content=message)]
        
        # Run the agent
        result = agent.invoke(state)
        
        # Extract response
        if result and "messages" in result:
            response = result["messages"][-1].content
        else:
            response = "I'm sorry, I couldn't process your request."
        
        return {
            "response": response,
            "model": MODEL_NAME,
            "timestamp": datetime.now().isoformat(),
            "tools_used": result.get("tools_used", [])
        }
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze-logs")
async def analyze_logs(request: Dict[str, Any]):
    """Direct log analysis endpoint"""
    try:
        query = request.get("query", "")
        if not query:
            raise HTTPException(status_code=400, detail="Query is required")
        
        # Use the query_loki_logs tool directly
        result = query_loki_logs(query)
        
        return {
            "query": query,
            "result": result,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error in analyze-logs endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/test-analysis")
async def test_analysis():
    """Analyze test failures"""
    try:
        result = analyze_test_failures()
        
        return {
            "analysis": result,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error in test-analysis endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/system-health")
async def system_health():
    """Get system health status"""
    try:
        result = get_system_health()
        
        return {
            "health": result,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error in system-health endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/monitoring/status")
async def monitoring_status():
    """Get monitoring status and alerts"""
    return {
        "monitoring_enabled": MONITORING_ENABLED,
        "monitoring_interval": MONITORING_INTERVAL,
        "alert_threshold": ALERT_THRESHOLD,
        "last_check": monitoring_state.get("last_check"),
        "error_count": monitoring_state.get("error_count", 0),
        "alerts": monitoring_state.get("alerts", []),
        "is_monitoring": monitoring_state.get("is_monitoring", False)
    }

@app.post("/monitoring/start")
async def start_monitoring_endpoint():
    """Start proactive monitoring"""
    try:
        start_monitoring()
        return {
            "status": "started",
            "message": "Proactive monitoring started",
            "interval": MONITORING_INTERVAL
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/monitoring/stop")
async def stop_monitoring_endpoint():
    """Stop proactive monitoring"""
    try:
        stop_monitoring()
        return {
            "status": "stopped",
            "message": "Proactive monitoring stopped"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    logger.info(f"Starting LangGraph Agent on port {AGENT_PORT}")
    logger.info(f"Ollama URL: {OLLAMA_URL}")
    logger.info(f"Model: {MODEL_NAME}")
    logger.info(f"Loki MCP URL: {LOKI_MCP_URL}")
    logger.info(f"Monitoring enabled: {MONITORING_ENABLED}")
    logger.info(f"Monitoring interval: {MONITORING_INTERVAL}s")
    
    # Start proactive monitoring if enabled
    if MONITORING_ENABLED:
        start_monitoring()
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=AGENT_PORT,
        log_level="info"
    )
