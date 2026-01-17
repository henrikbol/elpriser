# Elpriser - Dutch Electricity Spot Price Tracker
# Makefile for building and deploying the application

# Variables
APP_NAME = seal-app
REGISTRY = registry.digitalocean.com/uggiuggi
IMAGE_NAME = $(REGISTRY)/spot
# Auto-detect APP_ID from app name (you can override with: make deploy APP_ID=your-app-id)
APP_ID = $(shell doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | grep -w $(APP_NAME) | awk '{print $$1}')
PLATFORM = linux/amd64

# Colors for output
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m # No Color

.PHONY: help build push deploy logs status restart clean run dev test

# Default target
help:
	@echo "$(BLUE)Elpriser - Available Commands:$(NC)"
	@echo ""
	@echo "  $(GREEN)make build$(NC)        - Build Docker image for production"
	@echo "  $(GREEN)make push$(NC)         - Push Docker image to DigitalOcean registry"
	@echo "  $(GREEN)make deploy$(NC)       - Deploy to DigitalOcean App Platform"
	@echo "  $(GREEN)make all$(NC)          - Build, push, and deploy (full deployment)"
	@echo ""
	@echo "  $(YELLOW)make logs$(NC)         - View application logs"
	@echo "  $(YELLOW)make status$(NC)       - Check deployment status"
	@echo "  $(YELLOW)make restart$(NC)      - Restart the application"
	@echo ""
	@echo "  $(BLUE)make run$(NC)          - Run application locally with Docker Compose"
	@echo "  $(BLUE)make dev$(NC)          - Run application in development mode with hot reload"
	@echo "  $(BLUE)make stop$(NC)         - Stop running Docker containers"
	@echo "  $(BLUE)make clean$(NC)        - Clean up Docker images and containers"
	@echo ""
	@echo "  $(BLUE)make uv-sync$(NC)      - Sync dependencies with UV (local development)"
	@echo "  $(BLUE)make info$(NC)         - Show application information"
	@echo ""

# Build Docker image
build:
	@echo "$(BLUE)Building Docker image for production...$(NC)"
	docker buildx build --platform $(PLATFORM) --tag $(APP_NAME) .
	docker tag $(APP_NAME) $(IMAGE_NAME)
	@echo "$(GREEN)✓ Build complete$(NC)"

# Push to registry
push:
	@echo "$(BLUE)Pushing image to DigitalOcean registry...$(NC)"
	docker push $(IMAGE_NAME)
	@echo "$(GREEN)✓ Push complete$(NC)"

# Deploy to DigitalOcean
deploy:
	@echo "$(BLUE)Creating new deployment...$(NC)"
	@if [ -z "$(APP_ID)" ]; then \
		echo "$(YELLOW)ERROR: No app found with name '$(APP_NAME)'$(NC)"; \
		echo ""; \
		echo "Available apps:"; \
		doctl apps list --format ID,Spec.Name; \
		echo ""; \
		echo "Options:"; \
		echo "  1. Use an existing app: make deploy APP_ID=<app-id>"; \
		echo "  2. Change APP_NAME in Makefile to match an existing app"; \
		echo "  3. Create a new app in DigitalOcean App Platform first"; \
		exit 1; \
	fi
	doctl apps create-deployment $(APP_ID)
	@echo "$(GREEN)✓ Deployment initiated$(NC)"
	@echo "$(YELLOW)Check status with: make status$(NC)"

# Full deployment pipeline
all: build push deploy
	@echo "$(GREEN)✓ Full deployment complete!$(NC)"

# View logs
logs:
	@echo "$(BLUE)Fetching application logs...$(NC)"
	doctl apps logs $(APP_ID) --follow

# Check deployment status
status:
	@echo "$(BLUE)Checking deployment status...$(NC)"
	@doctl apps get $(APP_ID)
	@echo ""
	@echo "$(BLUE)Recent deployments:$(NC)"
	@doctl apps list-deployments $(APP_ID) | head -n 5

# Restart application
restart:
	@echo "$(BLUE)Restarting application...$(NC)"
	doctl apps restart $(APP_ID)
	@echo "$(GREEN)✓ Restart initiated$(NC)"

# Run locally with Docker Compose
run:
	@echo "$(BLUE)Running application locally with Docker Compose...$(NC)"
	docker-compose up --build

# Run in development mode with hot reload
dev:
	@echo "$(BLUE)Starting development server with hot reload...$(NC)"
	docker-compose up

# Stop Docker containers
stop:
	@echo "$(BLUE)Stopping Docker containers...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

# Clean up Docker resources
clean:
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	docker-compose down
	-docker rmi $(APP_NAME) 2>/dev/null || true
	-docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# Sync dependencies with UV (for local development)
uv-sync:
	@echo "$(BLUE)Syncing dependencies with UV...$(NC)"
	uv sync
	@echo "$(GREEN)✓ Dependencies synced$(NC)"

# Run with UV locally (without Docker)
uv-run:
	@echo "$(BLUE)Running application with UV locally...$(NC)"
	uv run uvicorn src.app:app --reload --host 0.0.0.0 --port 8080

# Get app info
info:
	@echo "$(BLUE)Application Information:$(NC)"
	@echo "  App Name:    $(APP_NAME)"
	@echo "  App ID:      $(APP_ID)"
	@echo "  Registry:    $(IMAGE_NAME)"
	@echo "  Platform:    $(PLATFORM)"
	@echo "  Port:        8080"
	@echo ""
	@if [ -n "$(APP_ID)" ]; then \
		doctl apps get $(APP_ID) --format ID,Spec.Name,DefaultIngress,ActiveDeployment.ID; \
	else \
		echo "$(YELLOW)No app found with name '$(APP_NAME)'$(NC)"; \
	fi

# List all apps
list:
	@echo "$(BLUE)All DigitalOcean Apps:$(NC)"
	@doctl apps list

# Get deployment details
deployment:
	@echo "$(BLUE)Current Deployment Details:$(NC)"
	@doctl apps list-deployments $(APP_ID) --format ID,Cause,Progress,CreatedAt | head -n 3

# Force rebuild and redeploy
force-deploy:
	@echo "$(BLUE)Force rebuilding and redeploying...$(NC)"
	doctl apps create-deployment $(APP_ID) --force-rebuild
	@echo "$(GREEN)✓ Force deployment initiated$(NC)"

# View local logs
local-logs:
	@echo "$(BLUE)Viewing local container logs...$(NC)"
	docker-compose logs -f

# Build without cache
rebuild:
	@echo "$(BLUE)Rebuilding Docker image without cache...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)✓ Rebuild complete$(NC)"
