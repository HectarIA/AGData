import 'package:geolocator/geolocator.dart';

class LocationService {
  // Retorna as coordenadas formatadas ou a mensagem de erro apropriada
  Future<String> getCoordinates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "GPS Desligado";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Permissão Negada";
    }

    if (permission == LocationPermission.deniedForever) {
      return "GPS Bloqueado nas Configurações";
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return "📍 Lat: ${position.latitude.toStringAsFixed(5)} | Lng: ${position.longitude.toStringAsFixed(5)}";
    } catch (e) {
      return "Erro ao buscar satélite";
    }
  }
}