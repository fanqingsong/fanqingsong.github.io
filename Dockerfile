# 使用 Python 3.11 slim 镜像作为基础镜像
FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# 配置 apt 使用中国镜像源
RUN echo "deb https://mirrors.aliyun.com/debian/ bookworm main non-free contrib" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm-updates main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm-backports main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bookworm-security main non-free contrib" >> /etc/apt/sources.list

# 配置 pip 使用中国镜像源
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ && \
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件（如果有的话）
# COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir \
    mkdocs-material \
    pymdown-extensions

# 暴露端口
EXPOSE 8000

# 默认命令 - 支持热加载
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000", "--livereload"] 