# 1. Instale dependências relevantes:
# pip install "langsmith[otel]" langchain logfire opentelemetry-api
# E drivers do Ollama/LangChain para usar localmente

# 2. Configure variáveis de ambiente:
import os

import logfire

sre_agent_token = os.getenv('LOGFIRE_TOKEN_SRE_AGENT')
logfire.configure(service_name="agent-demo", token=sre_agent_token)
# Se usar LangChain, integração OTel já ocorre via os env vars acima

# 4. Rode o modelo local:
from langchain_community.llms import Ollama
llm = Ollama(model="bruno-sre:latest", base_url="http://192.168.0.12:11434")  # ou outro modelo local

# 5. Crie seu agente e execute normalmente:
from langchain_core.prompts import ChatPromptTemplate
prompt = ChatPromptTemplate.from_template("Pergunta: {pergunta}")
chain = prompt | llm
response = chain.invoke({"pergunta": "Como integrar OTel com LangSmith?"})
print(response)
