# Elpriser - Dutch Electricity Spot Price Tracker

A real-time electricity spot price visualization application for Danisk (DK2 price area), built with FastAPI and Chart.js. Displays current and historical spot prices with green energy metrics.

## Quick Start

### Prerequisites

- Python 3.12+ (for local development)
- UV package manager (for local development)
- Docker and Docker Compose
- DigitalOcean CLI (`doctl`) (for deployment)
- DigitalOcean account with container registry access

### Installation

**Local Development with UV:**

```bash
# Install UV if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone the repository
git clone <repository-url>
cd elpriser

# Sync dependencies and create virtual environment
uv sync

# Run the application
uv run uvicorn src.app:app --reload --port 8080
```

Access on: http://localhost:8080

**Docker Development:**

```bash
# Run with hot reload
docker-compose up

# Or build and run
docker-compose up --build
```

Access on: http://localhost:8080

## Deployment

### Using Makefile (Recommended)

The project includes a comprehensive Makefile for easy deployment and management.

**Note**: The Makefile automatically detects your DigitalOcean App Platform APP_ID based on the app name (`seal-app`). This means you don't need to hardcode the APP_ID - it will be looked up automatically when you run any make command.

#### Full Deployment Pipeline

```bash
# Login to DigitalOcean registry first
doctl registry login

# Build, push, and deploy in one command
make all
```

#### Step-by-Step Deployment

```bash
# 1. Build Docker image for linux/amd64
make build

# 2. Push to DigitalOcean registry
make push

# 3. Deploy to App Platform
make deploy
```

#### Monitoring & Management

```bash
# View live logs from DigitalOcean
make logs

# Check deployment status
make status

# Get app information
make info

# Restart the application
make restart
```

#### Local Development

```bash
# Run with Docker Compose (with hot reload)
make dev

# Run and rebuild
make run

# Run with UV locally
make uv-run

# Sync UV dependencies
make uv-sync

# View local Docker logs
make local-logs

# Stop containers
make stop

# Clean up Docker resources
make clean
```

#### All Available Commands

Run `make` or `make help` to see all available commands:

- `make build` - Build Docker image for production
- `make push` - Push to DigitalOcean registry
- `make deploy` - Deploy to DigitalOcean App Platform
- `make all` - Full deployment pipeline (build + push + deploy)
- `make logs` - View DigitalOcean application logs
- `make status` - Check deployment status
- `make restart` - Restart application on DigitalOcean
- `make run` - Run locally with Docker Compose (build first)
- `make dev` - Run in development mode with hot reload
- `make stop` - Stop running Docker containers
- `make clean` - Clean up Docker resources
- `make uv-sync` - Sync dependencies with UV
- `make uv-run` - Run with UV locally (without Docker)
- `make info` - Show application information
- `make local-logs` - View local container logs
- `make rebuild` - Rebuild Docker image without cache
- `make force-deploy` - Force rebuild and deploy on DigitalOcean

### Manual Deployment (Alternative)

If you prefer to run commands manually:

```bash
# Build and push image
docker buildx build --platform linux/amd64 --tag spot .
docker tag spot registry.digitalocean.com/uggiuggi/spot
docker push registry.digitalocean.com/uggiuggi/spot

# Deploy to DigitalOcean (seal-app)
doctl apps create-deployment <APP_ID>
```

## Project Structure

```
elpriser/
├── src/
│   ├── app.py              # Main FastAPI application
│   ├── __init__.py
│   └── static/
│       ├── form.html       # Main template with Chart.js visualizations
│       ├── meter.html      # Additional meter template
│       ├── table.css       # Styling
│       ├── favicon.ico
│       └── apple-touch-icon.png
├── Dockerfile              # Production Docker build with UV
├── Dockerfile_example      # Reference UV pattern
├── docker-compose.yml      # Development environment with hot reload
├── Makefile               # Deployment automation
├── pyproject.toml         # UV/Python project configuration
├── uv.lock                # Locked dependencies
├── .python-version        # Python 3.12 specification
├── .gitignore
└── README.md
```

## Technology Stack

### Backend
- **Framework**: FastAPI 0.128+
- **Python**: 3.12
- **Package Manager**: UV (10-100x faster than pip)
- **Server**: Uvicorn 0.40+
- **Data Processing**: Pandas 2.3+
- **HTTP Client**: Requests 2.32+
- **Templating**: Jinja2 3.1+

### Frontend
- **Charts**: Chart.js 3.9.1
- **Styling**: Custom CSS with modern design
- **Data Visualization**: Bar charts for spot prices, doughnut charts for energy mix

### DevOps
- **Containerization**: Docker with UV-based multi-stage builds
- **Deployment**: DigitalOcean App Platform
- **Architecture**: linux/amd64
- **Development**: Hot reload with volume mounting

## Features

### Real-time Data Display
- Current electricity spot prices for DK2 (Netherlands/Denmark)
- 24-hour rolling average visualization
- Historical price trends
- Lowest price indication for the next period

### Green Energy Metrics
- Real-time renewable energy percentage
- Breakdown by source (Solar, Offshore Wind, Onshore Wind)
- Total production vs. green energy comparison

### Interactive Charts
- **Spot Price Chart**: Combined bar and line chart showing current prices and 24h rolling average
- **Energy Mix Chart**: Doughnut chart displaying energy production sources
- Color-coded visualization (current hour highlighted in red)

### Data Sources
All data is fetched from the Danish Energy Data Service API:
- **Spot Prices**: DayAheadPrices dataset (DK2 price area)
- **Energy Production**: PowerSystemRightNow dataset

## Configuration

### Price Area
The application is configured for DK2 price area (Netherlands). To change:

Edit `src/app.py`:
```python
SPOT_PRICE_URL = f"...filter=%7B%22PriceArea%22:[%22DK2%22]%7D..."
# Change DK2 to DK1 or other supported areas
```

### Port Configuration
- **Local Development**: Port 8080
- **Docker**: Port 8080 (configurable in docker-compose.yml)

### Chart Styling
Customize chart colors in `src/static/form.html`:
```javascript
const CHART_COLORS = {
    red: 'rgba(255, 99, 132, 1)',
    blue: 'rgba(54, 162, 235, 1)',
    // ... more colors
}
```

## Development Workflow

### Using UV (Recommended for Local Development)

```bash
# Install dependencies
uv sync

# Run with hot reload
uv run uvicorn src.app:app --reload --port 8080

# Add a new dependency
uv add package-name

# Update dependencies
uv lock --upgrade
```

### Using Docker (Recommended for Consistency)

```bash
# Development with hot reload
docker-compose up

# View logs
docker-compose logs -f

# Rebuild after dependency changes
docker-compose build --no-cache
docker-compose up
```

### Making Code Changes

With `make dev` running, any changes to files in `src/` will automatically reload the application thanks to volume mounting and uvicorn's `--reload` flag.

## Migration Notes

This project was recently migrated from pip to UV package manager:

### What Changed
- ✅ Python upgraded from 3.9 to 3.12 (~25% performance improvement)
- ✅ Dependencies managed via `pyproject.toml` instead of `requirements.txt`
- ✅ UV lock file for reproducible builds
- ✅ Dockerfile optimized for UV with multi-stage builds
- ✅ All dependencies updated to latest compatible versions
- ✅ Docker Compose configured with hot reload

### Benefits
- **Speed**: 10-100x faster dependency resolution
- **Reliability**: Deterministic builds via lock file
- **Performance**: Python 3.12 performance improvements
- **Modern**: Latest package versions with security fixes

## API Endpoints

- `GET /` - Main dashboard with spot price charts
- `GET /chrx` - Additional meter view

## Deployment Target

- **Platform**: DigitalOcean App Platform
- **App Name**: seal-app
- **Registry**: registry.digitalocean.com/uggiuggi/spot
- **Architecture**: linux/amd64

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and verify locally
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

MIT

## Acknowledgments

- Data provided by [Energinet's Data Service](https://www.energidataservice.dk/)
- Built with [FastAPI](https://fastapi.tiangolo.com/)
- Visualizations powered by [Chart.js](https://www.chartjs.org/)
- Package management by [UV](https://github.com/astral-sh/uv)
