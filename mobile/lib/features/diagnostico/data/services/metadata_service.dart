import 'dart:io';
import 'package:exif/exif.dart';

class MetadataService {
  Future<Map<String, double>?> extrairLocalizacaoDaFoto(File imagem) async {
    try {
      final bytes = await imagem.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty || !data.containsKey('GPS GPSLatitude')) {
        return null;
      }

      final latTag = data['GPS GPSLatitude'];
      final latRefTag = data['GPS GPSLatitudeRef'];
      final lngTag = data['GPS GPSLongitude'];
      final lngRefTag = data['GPS GPSLongitudeRef'];

      if (latTag == null || latRefTag == null || lngTag == null || lngRefTag == null) {
        return null;
      }

      final double? lat = _convertTagToDouble(latTag, latRefTag.printable);
      final double? lng = _convertTagToDouble(lngTag, lngRefTag.printable);

      if (lat != null && lng != null) {
        return {
          'latitude': lat,
          'longitude': lng,
        };
      }
    } catch (e) {
      print('Erro ao ler metadados: $e');
    }
    return null;
  }

  double? _convertTagToDouble(IfdTag tag, String ref) {
    final values = tag.values.toList();
    if (values.length < 3) return null;

    double d = values[0].toDouble();
    double m = values[1].toDouble();
    double s = values[2].toDouble();

    double result = d + (m / 60.0) + (s / 3600.0);

    if (ref == 'S' || ref == 'W') {
      result = -result;
    }
    return result;
  }
}