import 'dart:ffi';
import 'dart:io';

// Native fonksiyonu tanımlayan tipler
typedef heavy_computation_native_t = Int32 Function(Int32 input);
typedef HeavyComputation = int Function(int input);

// Platforma göre kütüphaneyi yükleme
final DynamicLibrary _nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_compute.so")
    : Platform.isIOS
        ? DynamicLibrary.process()
        : throw UnsupportedError("Unsupported platform");

// Dart-side fonksiyon sarmalayıcı
final HeavyComputation heavyComputation = _nativeLib
    .lookup<NativeFunction<heavy_computation_native_t>>( 'heavy_computation' )
    .asFunction<HeavyComputation>(); 