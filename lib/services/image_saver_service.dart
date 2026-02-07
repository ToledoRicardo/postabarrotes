import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Servicio para guardar imágenes en la galería del dispositivo.
/// Usa un MethodChannel directo en MainActivity — sin plugins externos.
class ImageSaverService {
  static const _channel = MethodChannel('com.example.tiendabarrotes/gallery');

  /// Guarda [imageBytes] (PNG/JPEG) en la galería con el [name] dado.
  /// Retorna un Map con 'isSuccess', 'filePath' y 'errorMessage'.
  static Future<Map<String, dynamic>> saveImage(
    Uint8List imageBytes, {
    int quality = 100,
    String? name,
  }) async {
    try {
      final result = await _channel.invokeMethod('saveImageToGallery', {
        'imageBytes': imageBytes,
        'quality': quality,
        'name': name,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'isSuccess': false,
        'filePath': null,
        'errorMessage': e.message ?? 'Error desconocido',
      };
    } catch (e) {
      return {
        'isSuccess': false,
        'filePath': null,
        'errorMessage': e.toString(),
      };
    }
  }
}
