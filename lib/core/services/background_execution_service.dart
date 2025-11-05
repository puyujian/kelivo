import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';

class BackgroundExecutionService {
  static const MethodChannel _channel = MethodChannel('app.background');
  
  bool _initialized = false;
  bool _enabled = false;
  bool _unavailable = false;

  bool get isInitialized => _initialized;
  bool get isEnabled => _enabled;
  bool get isUnavailable => _unavailable;

  bool get isSupported {
    try {
      if (Platform.isAndroid) return true;
      if (Platform.isIOS) return true;
      final os = Platform.operatingSystem.toLowerCase();
      if (os.contains('harmony') || os.contains('openharmony') || os.contains('ohos')) {
        return true;
      }
      final version = Platform.operatingSystemVersion.toLowerCase();
      if (version.contains('harmony') || version.contains('openharmony') || version.contains('ohos')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool get _isAndroidOrHarmony {
    try {
      if (Platform.isAndroid) return true;
    } catch (_) {}
    try {
      final os = Platform.operatingSystem.toLowerCase();
      if (os.contains('harmony') || os.contains('openharmony') || os.contains('ohos')) {
        return true;
      }
      final version = Platform.operatingSystemVersion.toLowerCase();
      if (version.contains('harmony') || version.contains('openharmony') || version.contains('ohos')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<bool> initialize() async {
    if (!isSupported || _unavailable) return false;
    if (_initialized) return !_unavailable;

    try {
      if (_isAndroidOrHarmony) {
        final androidConfig = const FlutterBackgroundAndroidConfig(
          notificationTitle: 'Kelivo',
          notificationText: 'Generating reply in background…',
          notificationImportance: AndroidNotificationImportance.normal,
          enableWifiLock: true,
        );
        final success = await FlutterBackground.initialize(androidConfig: androidConfig);
        _initialized = true;
        if (!success) {
          _unavailable = true;
        }
        return success;
      } else if (_isIOS) {
        final success = await _channel.invokeMethod<bool>('initialize') ?? false;
        _initialized = true;
        if (!success) {
          _unavailable = true;
        }
        return success;
      }
    } catch (_) {
      _initialized = true;
      _unavailable = true;
      return false;
    }
    return false;
  }

  Future<bool> hasPermissions() async {
    if (!isSupported || _unavailable) return false;
    
    try {
      if (_isAndroidOrHarmony) {
        return await FlutterBackground.hasPermissions;
      } else if (_isIOS) {
        return await _channel.invokeMethod<bool>('hasPermissions') ?? true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<bool> enable() async {
    if (!isSupported || _enabled || _unavailable) return false;
    
    final ready = await initialize();
    if (!ready) return false;

    try {
      bool success = false;
      if (_isAndroidOrHarmony) {
        success = await FlutterBackground.enableBackgroundExecution();
      } else if (_isIOS) {
        success = await _channel.invokeMethod<bool>('enableBackgroundExecution') ?? false;
      }
      
      _enabled = success;
      if (!success) {
        _unavailable = true;
      }
      return success;
    } catch (_) {
      _unavailable = true;
      _enabled = false;
      return false;
    }
  }

  Future<void> disable() async {
    if (!isSupported || !_enabled) return;

    try {
      if (_isAndroidOrHarmony) {
        await FlutterBackground.disableBackgroundExecution();
      } else if (_isIOS) {
        await _channel.invokeMethod('disableBackgroundExecution');
      }
    } catch (_) {}
    _enabled = false;
  }

  Future<bool> isBackgroundExecutionEnabled() async {
    if (!isSupported) return false;
    
    try {
      if (_isAndroidOrHarmony) {
        return FlutterBackground.isBackgroundExecutionEnabled;
      } else if (_isIOS) {
        return await _channel.invokeMethod<bool>('isBackgroundExecutionEnabled') ?? false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
