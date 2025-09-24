# 🚀 Bruno Site

A production-ready, dynamic Bruno site system showcasing SRE/DevSecOps and AI Engineering expertise. Built with modern cloud-native technologies and intelligent AI integration.

## 📋 Quick Overview

This Bruno site system demonstrates:
- **Dynamic Content Management** with real-time updates
- **AI-Powered Chatbot** using Ollama and Gemma3n
- **Production Infrastructure** with Kubernetes and monitoring
- **Modern DevOps Practices** with CI/CD and security scanning

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Go API        │    │   Database      │
│   (Static HTML) │◄──►│   (Gin)         │◄──►│   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Chatbot    │    │   Redis Cache   │    │   Observability │
│   (Ollama)      │    │   (Session)     │    │   (Prometheus)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Go 1.21+ (for development)
- Node.js 18+ (for frontend development)

### Start the System
```bash
# Clone the repository
git clone <repository-url>
cd bruno-dev

# Start all services
docker-compose up -d

# Access the application
open http://localhost:3000
```

## 📚 Documentation

### Core Documentation
- **[🤖 CHATBOT.md](./CHATBOT.md)** - AI Assistant with Ollama & Gemma3n integration
- **[🏗️ Architecture Guide](./portifolio-site/README.md)** - System architecture and deployment
- **[⚡ Performance Plan](./PERFORMANCE_OPTIMIZATION_PLAN.md)** - Performance optimization strategies

### Infrastructure & Security
- **[☁️ Cloudflare Setup](./CLOUDFLARE_SETUP_GUIDE.md)** - CDN and security configuration
- **[🔒 Security Report](./PENETRATION_TEST_REPORT.md)** - Security assessment and findings
- **[🛡️ Security Improvements](./SECURITY_IMPROVEMENTS_SUMMARY.md)** - Security enhancements

### Development
- **[🎨 Frontend Guide](./frontend/README.md)** - Frontend development and deployment
- **[📊 Cloudflare Summary](./CLOUDFLARE_IMPLEMENTATION_SUMMARY.md)** - CDN implementation details

## 🎯 Key Features

### 🤖 **AI-Powered Chatbot**
- **Ollama Integration**: Local AI inference for privacy and performance
- **Gemma3n Model**: Advanced language understanding
- **Context Awareness**: Maintains conversation history
- **Dynamic Responses**: Real-time project and skill information

### 📊 **Dynamic Content Management**
- **Real-time Updates**: Modify site content via API
- **Project Management**: CRUD operations for projects
- **Skill Matrix**: Dynamic skill updates
- **Experience Timeline**: Live career updates

### 🏗️ **Production Infrastructure**
- **Kubernetes Deployment**: Scalable container orchestration
- **Auto-scaling**: HPA based on CPU/memory usage
- **Health Monitoring**: Liveness and readiness probes
- **SSL/TLS**: Automatic certificate management

### 📈 **Observability Stack**
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and search
- **Custom Metrics**: Business and technical KPIs

## 🛠️ Technology Stack

### **Backend**
- **Go 1.21**: High-performance API server
- **Gin**: Fast HTTP web framework
- **GORM**: Database ORM
- **Redis**: Caching and sessions
- **PostgreSQL**: Primary database

### **Frontend**
- **Static HTML/CSS/JS**: Lightweight, fast-loading interface
- **Dynamic Content**: Real-time data from API
- **Responsive Design**: Works on all devices
- **AI Chatbot**: Intelligent conversation interface

### **AI & ML**
- **Ollama**: Local AI inference server
- **Gemma3n**: Advanced language model
- **Context Management**: Conversation state and knowledge
- **Dynamic Prompting**: Adaptive response generation

### **Infrastructure**
- **Kubernetes**: Container orchestration
- **Docker**: Containerization
- **Prometheus**: Monitoring
- **Grafana**: Visualization
- **Loki**: Log management

### **DevOps**
- **GitHub Actions**: CI/CD pipeline
- **k6**: Performance testing
- **Trivy**: Security scanning
- **Helm**: Kubernetes package management

## 📁 Project Structure

```
bruno-dev/
├── api/           # Go API server
├── frontend/      # Frontend application
├── portifolio-site/         # Static site assets
├── k8s/                    # Kubernetes manifests
├── k6/                     # Performance testing
├── CHATBOT.md              # AI Assistant documentation
├── README.md               # This file
└── [other .md files]       # Additional documentation
```

## 🚀 Development

### Frontend Development
```bash
cd frontend
npm install
npm run dev
```

### Backend Development
```bash
cd api
go mod tidy
go run main.go
```

### Infrastructure
```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Run performance tests
k6 run k6/load-test.js
```

## 📊 Monitoring & Analytics

- **Application Metrics**: Prometheus + Grafana
- **Log Aggregation**: Loki + Grafana
- **Performance Testing**: k6 load tests
- **Security Scanning**: Trivy vulnerability scanning

## 🔒 Security

- **HTTPS**: Automatic SSL/TLS with Cloudflare
- **Security Headers**: Comprehensive security headers
- **Vulnerability Scanning**: Automated security checks
- **Penetration Testing**: Regular security assessments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and security scans
5. Submit a pull request

## 📞 Contact

- **LinkedIn**: [Bruno Lucena](https://www.linkedin.com/in/bvlucena)
- **GitHub**: [brunovlucena](https://github.com/brunovlucena)
- **Bruno Site**: [Live Demo](http://localhost:3000)

---

*This Bruno site system demonstrates modern cloud-native development practices, AI integration, and production-ready infrastructure management.*
# bruno-site
