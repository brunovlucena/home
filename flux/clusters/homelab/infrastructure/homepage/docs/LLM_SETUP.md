# 🤖 LLM Chatbot Setup Guide

This guide explains how to set up and configure the new LLM-powered chatbot for Bruno Site.

## 🏗️ Architecture Overview

The new chatbot uses a **RAG (Retrieval-Augmented Generation)** approach:

1. **User Query** → **Context Builder** (queries PostgreSQL)
2. **Context Builder** → **LLM Service** (formats data for prompt)
3. **LLM Service** → **Gemma3** (via Ollama)
4. **Gemma3** → **Natural Language Response**

## 🚀 Quick Setup

### Using Ollama

```bash
# 1. Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# 2. Pull Gemma3n model (choose one based on your hardware)
ollama pull gemma3n:e4b  # Lightweight (4GB RAM) - Recommended
ollama pull gemma3n:e8b  # Better quality (8GB RAM)
ollama pull gemma3n:e12b # Best quality (12GB+ RAM)

# 3. Start Ollama (runs on port 11434)
# Note: Ollama server should be running on 192.168.0.3:11434
ollama serve --host 0.0.0.0:11434

# 4. Test the model
ollama run gemma3n:e4b
```

## ⚙️ Environment Configuration

Add these environment variables to your `.env` file:

```bash
# LLM Configuration
OLLAMA_URL=http://192.168.0.3:11434
GEMMA_MODEL=gemma3n:e4b         # or gemma3n:e8b, gemma3n:e12b
```

## 🔧 Backend Changes Made

### New Files Created:
- `api/services/context_builder.go` - Builds context from PostgreSQL data
- `api/services/llm_service.go` - Handles LLM communication

### Modified Files:
- `api/main.go` - Added LLM service initialization and `/api/chat` endpoint

### New API Endpoints:
- `POST /api/chat` - Main chat endpoint
- `GET /api/chat/health` - LLM health check

## 🎨 Frontend Changes Made

### Modified Files:
- `frontend/src/services/chatbot.ts` - Updated to use LLM backend with fallback

### New Features:
- **Hybrid Mode**: LLM responses with rule-based fallback
- **Health Monitoring**: Automatic LLM health checks
- **Contextual Suggestions**: Dynamic suggestions based on query type
- **Model Information**: Shows which model was used

## 🧪 Testing the Setup

### 1. Check LLM Health
```bash
curl http://localhost:8080/api/chat/health
```

Expected response:
```json
{
  "status": "healthy",
  "provider": "ollama",
  "model": "gemma3n:e4b",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 2. Test Chat Endpoint
```bash
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about Bruno'\''s experience with Kubernetes"}'
```

Expected response:
```json
{
  "response": "Bruno has extensive experience with Kubernetes...",
  "sources": ["PostgreSQL Database"],
  "model": "gemma3n:e4b",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🎯 How It Works

### Context Building Process:

1. **Query Analysis**: Determines what data to fetch based on keywords
2. **Data Retrieval**: Queries PostgreSQL for relevant:
   - Skills (from `skills` table)
   - Experience (from `experience` table)  
   - Projects (from `projects` table)
   - About info (from `content` table)
   - Contact info (from `content` table)

3. **Context Formatting**: Creates structured prompt with:
   ```
   You are Bruno's AI assistant. Answer questions about Bruno based on this data:
   
   ABOUT BRUNO: [description]
   SKILLS & TECHNOLOGIES: [categorized skills with proficiency]
   PROFESSIONAL EXPERIENCE: [chronological experience]
   KEY PROJECTS: [featured projects with technologies]
   CONTACT INFORMATION: [email, LinkedIn, etc.]
   
   USER QUESTION: [user's question]
   ```

4. **LLM Processing**: Sends formatted prompt to Gemma3n
5. **Response Generation**: Returns natural language response

### Fallback Strategy:

- **Primary**: LLM-generated responses using PostgreSQL context
- **Fallback**: Rule-based responses if LLM fails
- **Health Monitoring**: Automatic detection of LLM availability

## 🔍 Troubleshooting

### Common Issues:

1. **"LLM service health check failed"**
   - Ensure Ollama is running
   - Check if model is downloaded
   - Verify URL configuration

2. **"Context building failed"**
   - Check PostgreSQL connection
   - Verify database schema and data

3. **"LLM request timeout"**
   - Model might be too large for your hardware
   - Try a smaller model (gemma3n:e4b instead of gemma3n:e8b)

### Debug Commands:

```bash
# Check if Ollama is running
curl http://192.168.0.3:11434/api/tags



# Check database connection
psql postgres://bruno:bruno@localhost:5432/bruno -c "SELECT COUNT(*) FROM projects;"
```

## 🚀 Starting the System

```bash
# 1. Start PostgreSQL (if not running)
# 2. Start Redis (if not running)  
# 3. Start Ollama
ollama serve

# 4. Start the API server
cd api
go run main.go

# 5. Start the frontend
cd frontend  
npm run dev
```

## 📊 Performance Considerations

### Model Selection:
- **gemma3n:e4b**: Fast, low memory (4GB), good for development
- **gemma3n:e8b**: Balanced performance and quality (8GB)
- **gemma3n:e12b**: Best quality but requires 12GB+ RAM

### Optimization Tips:
- Use Redis caching for frequent queries
- Implement response caching for common questions
- Consider model quantization for better performance

## 🔒 Security Notes

- LLM endpoints use the same security middleware as other API endpoints
- Rate limiting is applied to prevent abuse
- SQL injection protection is maintained
- Context building sanitizes database inputs

## 🎉 What's New for Users

Users can now ask natural questions like:
- "What's Bruno's experience with cloud platforms?"
- "Tell me about his work at Notifi"
- "What programming languages does he know?"
- "Has he worked with Kubernetes in production?"
- "What's his background in AI/ML?"

The chatbot will provide detailed, contextual responses based on real data from your PostgreSQL database, powered by Gemma3n's natural language understanding.
