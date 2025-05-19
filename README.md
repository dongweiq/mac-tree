# Mac-Tree

macOS UI Element Tree Viewer 是一个用于查看和分析 macOS 应用程序 UI 元素层次结构的工具。

## 功能特点

- 实时查看 macOS 应用程序的 UI 元素树
- 支持元素属性查看
- 基于 Electron 的跨平台桌面应用
- 使用原生 macOS Accessibility API

## 技术栈

- Electron
- TypeScript
- Node.js Native Addon (node-addon-api)
- macOS Accessibility API

## 系统要求

- macOS 操作系统
- Node.js 14.0.0 或更高版本
- npm 6.0.0 或更高版本

## 安装

1. 克隆仓库：
```bash
git clone [repository-url]
cd mac-tree
```

2. 安装依赖：
```bash
npm install
```

3. 构建项目：
```bash
npm run build
```

## 开发

- 启动开发模式：
```bash
npm run dev
```

- 监视模式（自动编译）：
```bash
npm run watch
```

## 打包

生成 macOS 应用程序：
```bash
npm run pack
```

打包后的应用将在 `dist` 目录中生成。

## 项目结构

```
mac-tree/
├── src/
│   ├── main.ts           # 主进程代码
│   ├── ax-ui-element.ts  # UI元素处理
│   └── accessibility.mm  # 原生macOS Accessibility实现
├── build/                # 编译后的原生模块
├── dist/                 # 编译后的TypeScript代码
└── index.html           # 主窗口界面
```

## 许可证

ISC

## 作者

[作者名称] 王洪贺