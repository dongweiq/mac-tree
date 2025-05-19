import * as path from 'path';
import * as fs from 'fs';
import { execSync } from 'child_process';

let accessibility: any;

function getNativeModulePath() {
  // 开发环境
  let devPath = path.join(__dirname, '../build/Release/accessibility.node');
  if (fs.existsSync(devPath)) return devPath;

  // 生产环境（打包后）
  // __dirname: /Applications/mac-tree.app/Contents/Resources/app.asar/dist
  // 目标: /Applications/mac-tree.app/Contents/Resources/build/Release/accessibility.node
  let prodPath = path.join(process.resourcesPath, 'build/Release/accessibility.node');
  if (fs.existsSync(prodPath)) return prodPath;

  throw new Error('找不到原生模块 accessibility.node');
}

accessibility = require(getNativeModulePath());

class AXUIElement {
  static systemWide() {
    return accessibility.getSystemWideElement();
  }

  static async getElementTree(element: any) {
    const attributes = accessibility.getElementAttributes(element);
    const result: any = {
      role: attributes.role || 'Unknown',
      title: attributes.title || 'Untitled',
      children: []
    };

    if (attributes.children && Array.isArray(attributes.children)) {
      for (const child of attributes.children) {
        const childTree = await this.getElementTree(child);
        result.children.push(childTree);
      }
    }

    return result;
  }

  static async getAttribute(element: any, attribute: string) {
    try {
      return await accessibility.getElementAttribute(element, attribute);
    } catch (error) {
      return null;
    }
  }

  // 获取所有可见窗口列表（pid, app名, 窗口标题）
  static getWindowList() {
    console.log('[getWindowList] 开始获取窗口列表...');
    const script = `
      set output to "["
      tell application "System Events"
        set appList to (every process whose background only is false)
        repeat with proc in appList
          set appName to name of proc
          set pid to unix id of proc
          try
            repeat with w in windows of proc
              set winTitle to name of w
              if winTitle is not "" then
                if output is not "[" then
                  set output to output & ","
                end if
                set output to output & "{\\"pid\\":" & pid & ",\\"appName\\":\\"" & appName & "\\",\\"title\\":\\"" & winTitle & "\\"}"
              end if
            end repeat
          end try
        end repeat
      end tell
      set output to output & "]"
      return output
    `;
    
    try {
      const result = execSync(`osascript -e '${script.replace(/'/g, "'\\''")}'`).toString();
      console.log('[getWindowList] AppleScript 执行结果:', result);
      
      try {
        const windows = JSON.parse(result);
        console.log('[getWindowList] 解析成功，窗口列表:', windows);
        return windows;
      } catch (parseError) {
        console.error('[getWindowList] JSON 解析失败:', parseError);
        console.log('[getWindowList] 原始结果:', result);
        return [];
      }
    } catch (error) {
      console.error('[getWindowList] 执行 AppleScript 出错:', error);
      throw error;
    }
  }

  // 通过 pid 获取应用的主窗口 AXUIElement
  static getAppMainWindowElement(pid: number) {
    return accessibility.getAppMainWindowElement(pid);
  }
}

export = AXUIElement; 