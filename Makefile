.PHONY: help dev build preview clean install docker-dev docker-build docker-preview

# 默认目标
help:
	@echo "可用的命令:"
	@echo "  make dev          - 启动开发服务器 (本地)"
	@echo "  make build        - 构建静态文件 (本地)"
	@echo "  make preview      - 预览构建结果 (本地)"
	@echo "  make clean        - 清理构建文件"
	@echo "  make install      - 安装依赖"
	@echo "  make docker-dev   - 启动开发服务器 (Docker)"
	@echo "  make docker-build - 构建静态文件 (Docker)"
	@echo "  make docker-preview - 预览构建结果 (Docker)"

# 本地开发
dev:
	@echo "启动开发服务器..."
	@source venv/bin/activate && mkdocs serve

# 本地构建
build:
	@echo "构建静态文件..."
	@source venv/bin/activate && mkdocs build

# 本地预览
preview: build
	@echo "启动预览服务器..."
	@python3 -m http.server 8080 --directory site

# 清理
clean:
	@echo "清理构建文件..."
	@rm -rf site/
	@rm -rf .cache/

# 安装依赖
install:
	@echo "安装依赖..."
	@python3 -m venv venv
	@source venv/bin/activate && pip install mkdocs-material pymdown-extensions

# Docker 开发
docker-dev:
	@echo "启动 Docker 开发服务器..."
	@echo "访问地址: http://localhost:8001"
	@docker compose --profile dev up --build

# Docker 构建
docker-build:
	@echo "使用 Docker 构建静态文件..."
	@docker compose --profile build up --build

# Docker 预览
docker-preview:
	@echo "使用 Docker 预览构建结果..."
	@docker compose --profile preview up --build

# 完整 Docker 开发环境
docker-full:
	@echo "启动完整 Docker 开发环境..."
	@echo "访问地址: http://localhost:8001"
	@docker compose --profile full-dev up --build

# 停止所有容器
docker-stop:
	@echo "停止所有容器..."
	@docker compose down

# 重新构建并启动
docker-rebuild:
	@echo "重新构建并启动..."
	@docker compose down
	@docker compose --profile full-dev up --build

# 构建 Docker 镜像
docker-build-image:
	@echo "构建 Docker 镜像..."
	@docker build -t fanqingsong-site .

# 清理 Docker 资源
docker-clean:
	@echo "清理 Docker 资源..."
	@docker compose down --volumes --remove-orphans
	@docker image prune -f 