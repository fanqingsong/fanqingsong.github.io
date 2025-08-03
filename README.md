# Fan Qing Song's Personal Site

这是我的个人网站，集成了自我介绍和知识库。

## 🚀 快速开始

### 方法一：使用 Makefile（推荐）

```bash
# 查看所有可用命令
make help

# 安装依赖
make install

# 启动开发服务器
make dev

# 构建静态文件
make build

# 预览构建结果
make preview
```

### 方法二：使用 Docker Compose

```bash
# 启动开发服务器
make docker-dev

# 构建静态文件
make docker-build

# 预览构建结果
make docker-preview

# 完整开发环境
make docker-full

# 停止所有容器
make docker-stop
```

### 方法三：直接使用命令

```bash
# 安装依赖
python3 -m venv venv
source venv/bin/activate
pip install mkdocs-material pymdown-extensions

# 启动开发服务器
mkdocs serve

# 构建静态文件
mkdocs build
```

## 📁 项目结构

```
.
├── docs/                    # 文档源文件
│   ├── index.md            # 主页
│   ├── about-me.md         # 关于我
│   └── knowledge-base/     # 知识库
│       ├── index.md        # 知识库主页
│       ├── cheat_sheet.md  # 速查表
│       ├── linux_command.md # Linux 命令
│       ├── git_command.md  # Git 命令
│       ├── docker_*.md     # Docker 相关
│       ├── mysql_*.md      # MySQL 相关
│       ├── python_*.md     # Python 相关
│       └── sqlalchemy_*.md # SQLAlchemy 相关
├── site/                   # 构建输出目录
├── mkdocs.yml             # MkDocs 配置
├── docker-compose.yml     # Docker Compose 配置
├── Makefile               # 构建脚本
├── nginx.conf             # Nginx 配置
└── README.md              # 项目说明
```

## 🎨 功能特性

### 个人介绍
- 响应式设计
- 现代化 UI
- 技能展示
- 项目展示

### 知识库
- 结构化导航
- 搜索功能
- 代码高亮
- 暗色主题支持
- 移动端适配

### 技术栈
- **文档生成**: MkDocs + Material Theme
- **容器化**: Docker + Docker Compose
- **Web 服务器**: Nginx
- **构建工具**: Make

## 🌐 访问地址

- **开发服务器**: http://localhost:8001 (Docker) / http://localhost:8000 (本地)
- **预览服务器**: http://localhost:8080

## 📝 自定义配置

### 修改网站信息

编辑 `mkdocs.yml` 文件：

```yaml
site_name: Your Name's Site
site_description: Your site description
site_author: Your Name
site_url: https://your-domain.com
```

### 添加新页面

1. 在 `docs/` 目录下创建新的 Markdown 文件
2. 在 `mkdocs.yml` 的 `nav` 部分添加导航链接

### 修改主题

在 `mkdocs.yml` 的 `theme` 部分修改主题配置：

```yaml
theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
  palette:
    - scheme: default
      primary: indigo
      accent: indigo
```

## 🚀 部署

### GitHub Pages

1. 构建静态文件：
   ```bash
   make build
   ```

2. 将 `site/` 目录的内容推送到 GitHub Pages 分支

### 其他平台

构建后的 `site/` 目录包含所有静态文件，可以部署到任何静态文件托管服务。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

*这个项目集成了我的个人简历和知识库，希望能对大家有所帮助！* 