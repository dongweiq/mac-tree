import { app, BrowserWindow, ipcMain, shell } from 'electron';
import * as path from 'path';

let mainWindow: BrowserWindow | null = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, '../index.html'));
  mainWindow.webContents.openDevTools();
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// 获取系统权限状态
function checkAccessibilityPermission(): boolean {
  if (process.platform !== 'darwin') {
    console.log('[权限检测] 非 macOS 平台，直接返回 false');
    sendLogToRenderer('log', '[权限检测] 非 macOS 平台，直接返回 false');
    return false;
  }
  try {
    const AXUIElement = require('./ax-ui-element');
    console.log('[权限检测] 尝试调用 AXUIElement.systemWide()');
    sendLogToRenderer('log', '[权限检测] 尝试调用 AXUIElement.systemWide()');
    AXUIElement.systemWide();
    console.log('[权限检测] AXUIElement.systemWide() 调用成功，有辅助功能权限');
    sendLogToRenderer('log', '[权限检测] AXUIElement.systemWide() 调用成功，有辅助功能权限');
    return true;
  } catch (error) {
    console.error('[权限检测] AXUIElement.systemWide() 调用失败，错误信息如下：');
    sendLogToRenderer('error', '[权限检测] AXUIElement.systemWide() 调用失败，错误信息如下：', error);
    console.error(error);
    // 没有权限时弹出设置界面
    shell.openExternal('x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility');
    return false;
  }
}

// 请求辅助功能权限
ipcMain.handle('request-accessibility-permission', async () => {
  if (process.platform === 'darwin') {
    // 在 macOS 中打开系统偏好设置的安全性与隐私面板
    await shell.openExternal('x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility');
    return true;
  }
  return false;
});

// 检查辅助功能权限状态
ipcMain.handle('check-accessibility-permission', () => {
  return checkAccessibilityPermission();
});

// 监听渲染进程请求
ipcMain.handle('get-ui-element-tree', async () => {
  if (!checkAccessibilityPermission()) {
    throw new Error('需要辅助功能权限才能访问 UI 元素');
  }

  const AXUIElement = require('./ax-ui-element');
  const systemWide = AXUIElement.systemWide();
  return AXUIElement.getElementTree(systemWide);
});

function sendLogToRenderer(type: 'log' | 'error', ...args: any[]) {
  if (mainWindow && mainWindow.webContents) {
    mainWindow.webContents.send('main-log', { type, args: args.map(String) });
  }
} 