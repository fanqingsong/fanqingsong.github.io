# 使用说明

## 🎯 项目概述

这个项目成功集成了两个原有项目：

1. **aboutme** - 个人简历项目（Vue.js 动态简历）
2. **memo** - 知识库项目（常用命令和技巧）

现在统一使用 MkDocs + Material Theme 构建，提供了更好的文档体验和导航结构。

## 🚀 如何查看效果

### 方法一：本地开发（推荐）

```bash
# 1. 安装依赖
make install

# 2. 启动开发服务器
make dev

# 3. 在浏览器中访问
# http://localhost:8000 (本地开发)
```

### 方法二：Docker 开发

```bash
# 1. 启动 Docker 开发环境
make docker-dev

# 2. 在浏览器中访问
# http://localhost:8001 (Docker 开发)
```

### 方法三：直接使用命令

```bash
# 1. 激活虚拟环境
source venv/bin/activate

# 2. 启动开发服务器
mkdocs serve

# 3. 在浏览器中访问
# http://localhost:8000
```

## 📁 项目结构说明

```
docs/
├── index.md                    # 主页 - 网站概览
├── about-me.md                 # 关于我 - 个人简历和介绍
└── knowledge-base/             # 知识库目录
    ├── index.md                # 知识库主页
    ├── cheat_sheet.md          # 常用命令速查表
    ├── linux_command.md        # Linux 系统命令
    ├── git_command.md          # Git 版本控制命令
    ├── nodejs.md               # Node.js 相关命令
    ├── docker_*.md             # Docker 相关文档
    ├── mysql_*.md              # MySQL 相关文档
    ├── python_commands.md      # Python 命令
    └── sqlalchemy_*.md         # SQLAlchemy 相关文档
```

## 🎨 主要功能

### 1. 个人介绍页面
- 个人简历展示
- 技能和经验介绍
- 项目展示
- 联系方式

### 2. 知识库功能
- **结构化导航**: 清晰的分类和层级结构
- **搜索功能**: 全文搜索，快速找到需要的内容
- **代码高亮**: 支持多种编程语言的语法高亮
- **响应式设计**: 支持桌面和移动设备
- **暗色主题**: 支持明暗主题切换

### 3. 技术特性
- **现代化 UI**: Material Design 主题
- **快速加载**: 静态文件生成，加载速度快
- **SEO 友好**: 良好的搜索引擎优化
- **易于维护**: Markdown 格式，易于编辑和更新

## 🔧 常用命令

### 开发相关
```bash
make help          # 查看所有可用命令
make dev           # 启动开发服务器
make build         # 构建静态文件
make preview       # 预览构建结果
make clean         # 清理构建文件
```

### Docker 相关
```bash
make docker-dev    # Docker 开发环境
make docker-build  # Docker 构建
make docker-stop   # 停止所有容器
```

### 部署相关
```bash
./deploy.sh        # 构建项目
./deploy.sh --deploy  # 构建并部署到 GitHub Pages
```

## 📝 自定义和扩展

### 添加新页面
1. 在 `docs/` 目录下创建新的 `.md` 文件
2. 在 `mkdocs.yml` 的 `nav` 部分添加导航链接
3. 重新启动开发服务器查看效果

### 修改主题
编辑 `mkdocs.yml` 文件中的 `theme` 部分：
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

### 添加插件
在 `mkdocs.yml` 的 `plugins` 部分添加需要的插件：
```yaml
plugins:
  - search
  - minify  # 需要先安装 mkdocs-minify-plugin
```

## 🌐 部署选项

### GitHub Pages
1. 运行 `./deploy.sh --deploy`
2. 在 GitHub 仓库设置中启用 GitHub Pages
3. 选择 gh-pages 分支作为源

### 其他静态托管服务
1. 运行 `make build` 或 `./deploy.sh`
2. 将 `site/` 目录的内容上传到你的托管服务

### 自托管
1. 构建静态文件
2. 使用 Nginx 或 Apache 配置 Web 服务器
3. 将 `site/` 目录设置为网站根目录

## 🐛 常见问题

### Q: 开发服务器无法启动
A: 检查是否安装了依赖：
```bash
make install
```

### Q: 页面显示异常
A: 检查 MkDocs 配置文件和 Markdown 语法

### Q: Docker 容器无法启动
A: 检查 Docker 是否正在运行，端口是否被占用

### Q: 构建失败
A: 检查 `mkdocs.yml` 配置文件语法是否正确

## 📞 技术支持

如果遇到问题，可以：
1. 查看项目 README.md
2. 检查 MkDocs 官方文档
3. 在 GitHub 上创建 Issue

---

*这个项目现在集成了你的个人简历和知识库，提供了一个统一的个人网站解决方案！* 