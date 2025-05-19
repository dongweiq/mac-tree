#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#include <napi.h>

// 辅助函数：打印支持的属性列表
void LogSupportedAttributes(AXUIElementRef element) {
    CFArrayRef supportedAttributes;
    if (AXUIElementCopyAttributeNames(element, &supportedAttributes) == kAXErrorSuccess) {
        NSMutableString *attrList = [NSMutableString string];
        CFIndex count = CFArrayGetCount(supportedAttributes);
        [attrList appendString:@"支持的属性: "];
        for (CFIndex i = 0; i < count; i++) {
            CFStringRef attrName = (CFStringRef)CFArrayGetValueAtIndex(supportedAttributes, i);
            [attrList appendFormat:@"%@, ", (__bridge NSString*)attrName];
        }
        NSLog(@"%@", attrList);
        CFRelease(supportedAttributes);
    } else {
        NSLog(@"获取支持的属性失败");
    }
}

Napi::Object GetElementAttributes(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (!info[0].IsExternal()) {
        Napi::TypeError::New(env, "Wrong arguments").ThrowAsJavaScriptException();
        return Napi::Object::New(env);
    }

    AXUIElementRef element = static_cast<AXUIElementRef>(info[0].As<Napi::External<void>>().Data());
    Napi::Object result = Napi::Object::New(env);
    
    // 打印支持的属性
    LogSupportedAttributes(element);
    
    // 基本属性
    CFTypeRef value;
    
    // 角色
    if (AXUIElementCopyAttributeValue(element, kAXRoleAttribute, &value) == kAXErrorSuccess) {
        NSString *strValue = (__bridge NSString*)value;
        NSLog(@"角色: %@", strValue);
        result.Set("role", [strValue UTF8String]);
        CFRelease(value);
    } else {
        NSLog(@"获取角色失败");
    }
    
    // 标题
    if (AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &value) == kAXErrorSuccess) {
        NSString *strValue = (__bridge NSString*)value;
        NSLog(@"标题: %@", strValue);
        result.Set("title", [strValue UTF8String]);
        CFRelease(value);
    } else {
        NSLog(@"获取标题失败");
    }

    // 值
    if (AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value) == kAXErrorSuccess) {
        NSLog(@"值的类型: %@", CFGetTypeID(value) == CFStringGetTypeID() ? @"字符串" : @"数字");
        if (CFGetTypeID(value) == CFStringGetTypeID()) {
            NSString *strValue = (__bridge NSString*)value;
            NSLog(@"字符串值: %@", strValue);
            result.Set("value", [strValue UTF8String]);
        } else if (CFGetTypeID(value) == CFNumberGetTypeID()) {
            double numValue;
            CFNumberGetValue((CFNumberRef)value, kCFNumberDoubleType, &numValue);
            NSLog(@"数字值: %f", numValue);
            result.Set("value", numValue);
        }
        CFRelease(value);
    } else {
        NSLog(@"获取值失败");
    }

    // 位置
    AXValueRef positionValue;
    if (AXUIElementCopyAttributeValue(element, kAXPositionAttribute, (CFTypeRef*)&positionValue) == kAXErrorSuccess) {
        CGPoint point;
        if (AXValueGetValue(positionValue, (AXValueType)kAXValueCGPointType, &point)) {
            NSLog(@"位置: (%f, %f)", point.x, point.y);
            Napi::Object pointObj = Napi::Object::New(env);
            pointObj.Set("x", point.x);
            pointObj.Set("y", point.y);
            result.Set("position", pointObj);
        } else {
            NSLog(@"转换位置值失败");
        }
        CFRelease(positionValue);
    } else {
        NSLog(@"获取位置失败");
    }

    // 大小
    AXValueRef sizeValue;
    if (AXUIElementCopyAttributeValue(element, kAXSizeAttribute, (CFTypeRef*)&sizeValue) == kAXErrorSuccess) {
        CGSize size;
        if (AXValueGetValue(sizeValue, (AXValueType)kAXValueCGSizeType, &size)) {
            NSLog(@"大小: %f x %f", size.width, size.height);
            Napi::Object sizeObj = Napi::Object::New(env);
            sizeObj.Set("width", size.width);
            sizeObj.Set("height", size.height);
            result.Set("size", sizeObj);
        } else {
            NSLog(@"转换大小值失败");
        }
        CFRelease(sizeValue);
    } else {
        NSLog(@"获取大小失败");
    }

    // 是否启用
    if (AXUIElementCopyAttributeValue(element, kAXEnabledAttribute, &value) == kAXErrorSuccess) {
        bool enabled = CFBooleanGetValue((CFBooleanRef)value);
        NSLog(@"启用状态: %@", enabled ? @"是" : @"否");
        result.Set("enabled", enabled);
        CFRelease(value);
    } else {
        NSLog(@"获取启用状态失败");
    }

    // 是否聚焦
    if (AXUIElementCopyAttributeValue(element, kAXFocusedAttribute, &value) == kAXErrorSuccess) {
        bool focused = CFBooleanGetValue((CFBooleanRef)value);
        NSLog(@"聚焦状态: %@", focused ? @"是" : @"否");
        result.Set("focused", focused);
        CFRelease(value);
    } else {
        NSLog(@"获取聚焦状态失败");
    }

    // 子元素
    CFArrayRef childrenRef;
    if (AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, (CFTypeRef*)&childrenRef) == kAXErrorSuccess) {
        Napi::Array children = Napi::Array::New(env);
        CFIndex count = CFArrayGetCount(childrenRef);
        
        for (CFIndex i = 0; i < count; i++) {
            AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(childrenRef, i);
            CFRetain(child);
            children.Set(uint32_t(i), Napi::External<void>::New(env, (void*)child, [](Napi::Env env, void* data) {
                CFRelease((AXUIElementRef)data);
            }));
        }
        
        result.Set("children", children);
        CFRelease(childrenRef);
    }
    
    return result;
}

Napi::Value GetSystemWideElement(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    AXUIElementRef systemWide = AXUIElementCreateSystemWide();
    return Napi::External<void>::New(env, (void*)systemWide, [](Napi::Env env, void* data) {
        CFRelease((AXUIElementRef)data);
    });
}

Napi::Value GetAppMainWindowElement(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (!info[0].IsNumber()) {
        Napi::TypeError::New(env, "Wrong arguments, expected PID number").ThrowAsJavaScriptException();
        return env.Null();
    }

    pid_t pid = info[0].As<Napi::Number>().Int32Value();
    AXUIElementRef appRef = AXUIElementCreateApplication(pid);
    
    if (!appRef) {
        return env.Null();
    }

    // 获取应用的窗口
    CFArrayRef windowArray;
    AXError result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef*)&windowArray);
    
    if (result != kAXErrorSuccess || !windowArray) {
        CFRelease(appRef);
        return env.Null();
    }

    // 获取第一个窗口（主窗口）
    AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowArray, 0);
    CFRetain(windowRef);
    
    CFRelease(windowArray);
    CFRelease(appRef);

    return Napi::External<void>::New(env, (void*)windowRef, [](Napi::Env env, void* data) {
        CFRelease((AXUIElementRef)data);
    });
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
    exports.Set("getSystemWideElement", Napi::Function::New(env, GetSystemWideElement));
    exports.Set("getElementAttributes", Napi::Function::New(env, GetElementAttributes));
    exports.Set("getAppMainWindowElement", Napi::Function::New(env, GetAppMainWindowElement));
    return exports;
}

NODE_API_MODULE(accessibility, Init) 