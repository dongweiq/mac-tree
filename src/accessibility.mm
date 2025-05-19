#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#include <napi.h>

Napi::Object GetElementAttributes(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (!info[0].IsExternal()) {
        Napi::TypeError::New(env, "Wrong arguments").ThrowAsJavaScriptException();
        return Napi::Object::New(env);
    }

    AXUIElementRef element = static_cast<AXUIElementRef>(info[0].As<Napi::External<void>>().Data());
    
    Napi::Object result = Napi::Object::New(env);
    
    // Get role
    CFStringRef roleValue;
    if (AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (CFTypeRef*)&roleValue) == kAXErrorSuccess) {
        NSString *role = (__bridge NSString*)roleValue;
        result.Set("role", [role UTF8String]);
        CFRelease(roleValue);
    }
    
    // Get title
    CFStringRef titleValue;
    if (AXUIElementCopyAttributeValue(element, kAXTitleAttribute, (CFTypeRef*)&titleValue) == kAXErrorSuccess) {
        NSString *title = (__bridge NSString*)titleValue;
        result.Set("title", [title UTF8String]);
        CFRelease(titleValue);
    }
    
    // Get children
    CFArrayRef childrenRef;
    if (AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, (CFTypeRef*)&childrenRef) == kAXErrorSuccess) {
        Napi::Array children = Napi::Array::New(env);
        CFIndex count = CFArrayGetCount(childrenRef);
        
        for (CFIndex i = 0; i < count; i++) {
            AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(childrenRef, i);
            CFRetain(child); // Retain the child element
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
    CFRetain(windowRef);  // 增加引用计数
    
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