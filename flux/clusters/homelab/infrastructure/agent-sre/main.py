#!/usr/bin/env python3
"""
SRE Agent Test Script
Tests the SRE agent functionality with proper environment variable configuration
"""

import os
import logfire

# Configure Logfire with environment variable
sre_agent_token = os.getenv('LOGFIRE_TOKEN_SRE_AGENT')
if sre_agent_token:
    logfire.configure(service_name="sre-agent", token=sre_agent_token)
    print("✅ Logfire configured successfully")
else:
    print("⚠️  LOGFIRE_TOKEN_SRE_AGENT not set, skipping Logfire configuration")

# Configure LangChain API key from environment
langsmith_api_key = os.getenv('LANGSMITH_API_KEY')
if langsmith_api_key:
    os.environ['LANGCHAIN_API_KEY'] = langsmith_api_key
    print("✅ LangSmith API key configured from environment")
else:
    print("⚠️  LANGSMITH_API_KEY not set, LangSmith features will be limited")

# Test local Ollama connection
from langchain_community.llms import Ollama

try:
    llm = Ollama(model="bruno-sre:latest", base_url="http://192.168.0.12:11434")
    print("✅ Ollama connection established")
    
    # Test a simple query
    from langchain.prompts import ChatPromptTemplate
    prompt = ChatPromptTemplate.from_template("SRE Question: {question}")
    chain = prompt | llm
    
    response = chain.invoke({"question": "How do I monitor Kubernetes pods?"})
    print(f"🤖 Agent Response: {response}")
    
except Exception as e:
    print(f"❌ Error connecting to Ollama: {e}")

print("🏁 Test completed")
