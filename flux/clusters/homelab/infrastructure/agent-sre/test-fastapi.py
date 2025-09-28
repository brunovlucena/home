#!/usr/bin/env python3
"""
FastAPI SRE Agent Test Script
Tests FastAPI integration with SRE agent functionality
"""

import os
import logfire
from fastapi import FastAPI

# Configure Logfire with environment variable
sre_agent_token = os.getenv('LOGFIRE_TOKEN_SRE_AGENT')
if sre_agent_token:
    logfire.configure(service_name="sre-fastapi", token=sre_agent_token)
    print("✅ Logfire configured for FastAPI")
else:
    print("⚠️  LOGFIRE_TOKEN_SRE_AGENT not set, skipping Logfire configuration")

# Configure LangChain API key from environment
langsmith_api_key = os.getenv('LANGSMITH_API_KEY')
if langsmith_api_key:
    os.environ['LANGCHAIN_API_KEY'] = langsmith_api_key
    print("✅ LangSmith API key configured from environment")
else:
    print("⚠️  LANGSMITH_API_KEY not set, LangSmith features will be limited")

# Create FastAPI app
app = FastAPI(title="SRE Agent API", version="1.0.0")

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "SRE Agent API is running", "status": "healthy"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "sre-agent"}

@app.post("/ask")
async def ask_sre_agent(question: str):
    """Ask the SRE agent a question"""
    try:
        from langchain_community.llms import Ollama
        from langchain_core.prompts import ChatPromptTemplate
        
        llm = Ollama(model="bruno-sre:latest", base_url="http://192.168.0.12:11434")
        prompt = ChatPromptTemplate.from_template("SRE Expert Question: {question}")
        chain = prompt | llm
        
        response = chain.invoke({"question": question})
        return {"question": question, "answer": response, "status": "success"}
        
    except Exception as e:
        return {"question": question, "error": str(e), "status": "error"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting SRE Agent FastAPI server...")
    uvicorn.run(app, host="0.0.0.0", port=8080)
