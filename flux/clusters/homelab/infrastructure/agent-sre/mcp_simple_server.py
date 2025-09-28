#!/usr/bin/env python3
"""
Simple Working MCP Server
No external dependencies beyond what's already available
"""

import os
import json
import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
from aiohttp import web
from aiohttp.web import Request, Response

# Import the SRE agent from main.py
from main import agent, logger

class SimpleMCPServer:
    """Simple MCP Server that actually works."""
    
    def __init__(self):
        self.sre_agent = agent
        self.app = web.Application()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup HTTP routes."""
        # Add routes with and without query parameters
        self.app.router.add_post('/mcp', self.handle_mcp_request)
        self.app.router.add_get('/mcp', self.handle_mcp_info)
        self.app.router.add_get('/health', self.handle_health)
        self.app.router.add_get('/sse', self.handle_sse)
        
        # Add route for mcp with query parameters (for mcp-remote compatibility)
        self.app.router.add_post('/mcp/', self.handle_mcp_request)
        self.app.router.add_get('/mcp/', self.handle_mcp_info)
    
    async def handle_mcp_info(self, request: Request) -> Response:
        """Handle GET requests."""
        return web.json_response({
            "name": "sre-agent-simple-mcp",
            "version": "1.0.0",
            "description": "Simple SRE Agent MCP Server",
            "protocol": "mcp",
            "capabilities": {
                "tools": True,
                "resources": False,
                "prompts": False
            }
        })
    
    async def handle_mcp_request(self, request: Request) -> Response:
        """Handle MCP JSON-RPC 2.0 requests."""
        try:
            data = await request.json()
            
            # Handle notifications (no id field)
            if 'method' in data and 'id' not in data:
                method = data.get('method')
                if method == 'notifications/initialized':
                    return web.json_response({})  # Empty response for notifications
                else:
                    return web.json_response({})  # Empty response for other notifications
            
            if 'method' in data and 'id' in data:
                method = data.get('method')
                params = data.get('params', {})
                request_id = data.get('id')
                
                if method == 'initialize':
                    return web.json_response({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "protocolVersion": "2024-11-05",
                            "capabilities": {
                                "tools": {}
                            },
                            "serverInfo": {
                                "name": "sre-agent-simple-mcp",
                                "version": "1.0.0"
                            }
                        }
                    })
                
                elif method == 'tools/list':
                    tools = [
                        {
                            "name": "sre_chat",
                            "description": "General SRE chat and consultation",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "message": {
                                        "type": "string",
                                        "description": "Your SRE question or request"
                                    }
                                },
                                "required": ["message"]
                            }
                        },
                        {
                            "name": "analyze_logs",
                            "description": "Analyze logs for SRE insights",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "logs": {
                                        "type": "string",
                                        "description": "Log data to analyze"
                                    }
                                },
                                "required": ["logs"]
                            }
                        },
                        {
                            "name": "health_check",
                            "description": "Check the health status",
                            "inputSchema": {
                                "type": "object",
                                "properties": {}
                            }
                        }
                    ]
                    
                    return web.json_response({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "tools": tools
                        }
                    })
                
                elif method == 'tools/call':
                    tool_name = params.get('name')
                    arguments = params.get('arguments', {})
                    
                    if not tool_name:
                        return web.json_response({
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "error": {
                                "code": -32602,
                                "message": "Tool name is required"
                            }
                        })
                    
                    result = await self._execute_tool(tool_name, arguments)
                    return web.json_response({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": result
                                }
                            ]
                        }
                    })
                
                else:
                    return web.json_response({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": {
                            "code": -32601,
                            "message": f"Unknown method: {method}"
                        }
                    })
            
            else:
                return web.json_response({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32700,
                        "message": "Parse error"
                    }
                }, status=400)
                
        except Exception as e:
            logger.error(f"Error handling MCP request: {e}")
            return web.json_response({
                "jsonrpc": "2.0",
                "error": {
                    "code": -32603,
                    "message": str(e)
                }
            }, status=500)
    
    async def _execute_tool(self, name: str, arguments: Dict[str, Any]) -> str:
        """Execute the specified SRE tool."""
        try:
            if name == "sre_chat":
                message = arguments.get("message", "")
                if not message:
                    return "Error: Message is required for sre_chat"
                response = await self.sre_agent.chat(message)
                return response
            
            elif name == "analyze_logs":
                logs = arguments.get("logs", "")
                if not logs:
                    return "Error: Logs are required for analyze_logs"
                analysis = await self.sre_agent.analyze_logs(logs)
                return analysis
            
            elif name == "health_check":
                health = await self.sre_agent.health_check()
                return json.dumps(health, indent=2)
            
            else:
                return f"❌ Unknown tool: {name}"
        
        except Exception as e:
            logger.error(f"Error executing tool {name}: {e}")
            return f"Error executing tool {name}: {str(e)}"
    
    async def handle_health(self, request: Request) -> Response:
        """Health check endpoint."""
        health_status = await self.sre_agent.health_check()
        return web.json_response(health_status)
    
    async def handle_sse(self, request: Request) -> Response:
        """Simple SSE endpoint."""
        response = web.StreamResponse()
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['Connection'] = 'keep-alive'
        
        await response.prepare(request)
        
        try:
            # Send initial event
            await response.write(b"data: {\"type\": \"connected\", \"timestamp\": \"" + 
                               datetime.now().isoformat().encode() + b"\"}\n\n")
            
            # Send heartbeat every 5 seconds
            for i in range(10):  # Send 10 heartbeats
                await asyncio.sleep(5)
                await response.write(b"data: {\"type\": \"heartbeat\", \"count\": " + 
                                   str(i).encode() + b"}\n\n")
                
        except Exception as e:
            logger.error(f"SSE error: {e}")
        finally:
            await response.write_eof()
        
        return response
    
    async def start_server(self, host: str = "0.0.0.0", port: int = 30120):
        """Start the MCP server."""
        runner = web.AppRunner(self.app)
        await runner.setup()
        site = web.TCPSite(runner, host, port)
        await site.start()
        
        logger.info(f"🌐 Simple MCP Server started on {host}:{port}")
        logger.info(f"📋 MCP endpoint: http://localhost:{port}/mcp")
        logger.info(f"📡 SSE endpoint: http://localhost:{port}/sse")
        
        return runner

async def main():
    """Main entry point."""
    logger.info("🚀 Starting Simple SRE Agent MCP Server")
    
    # Configure server options
    host = os.getenv("MCP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_PORT", "30120"))
    
    server = SimpleMCPServer()
    runner = await server.start_server(host, port)
    
    try:
        logger.info("🏁 Simple MCP Server is running...")
        await asyncio.Event().wait()  # Run forever
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
    finally:
        await runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
