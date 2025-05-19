import * as path from 'path';
import * as fs from 'fs';

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
}

export = AXUIElement; 