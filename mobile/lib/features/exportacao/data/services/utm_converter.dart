import 'dart:math';

/// Resultado de uma conversão lat/lon (WGS84) para UTM.
class CoordenadaUtm {
  final double leste;
  final double norte;
  final int zona;
  final bool hemisferioSul;

  const CoordenadaUtm({
    required this.leste,
    required this.norte,
    required this.zona,
    required this.hemisferioSul,
  });
}

/// Converte coordenadas geográficas (graus decimais, WGS84) para UTM.
///
/// Monitores de pulverização de taxa variável esperam shapefile projetado
/// em metros planos (UTM), não em graus decimais — coordenadas em graus
/// geram erro de escala nesse tipo de equipamento. Fórmula padrão de
/// projeção Transversa de Mercator (datum WGS84), a mesma usada pela
/// maioria das bibliotecas GIS de código aberto.
class UtmConverter {
  static const double _a = 6378137.0; // semieixo maior WGS84
  static const double _eccSquared = 0.00669438; // excentricidade ao quadrado WGS84
  static const double _k0 = 0.9996;

  static int zonaUtm(double longitude) {
    return ((longitude + 180) / 6).floor() + 1;
  }

  static CoordenadaUtm converter(double latitude, double longitude) {
    final zona = zonaUtm(longitude);
    final latRad = latitude * pi / 180.0;
    final lonRad = longitude * pi / 180.0;

    final lonOrigemGraus = (zona - 1) * 6 - 180 + 3;
    final lonOrigemRad = lonOrigemGraus * pi / 180.0;

    const eccPrimeSquared = _eccSquared / (1 - _eccSquared);

    final sinLat = sin(latRad);
    final cosLat = cos(latRad);
    final tanLat = tan(latRad);

    final n = _a / sqrt(1 - _eccSquared * sinLat * sinLat);
    final t = tanLat * tanLat;
    final c = eccPrimeSquared * cosLat * cosLat;
    final aCoef = cosLat * (lonRad - lonOrigemRad);

    final m = _a *
        ((1 -
                    _eccSquared / 4 -
                    3 * _eccSquared * _eccSquared / 64 -
                    5 * _eccSquared * _eccSquared * _eccSquared / 256) *
                latRad -
            (3 * _eccSquared / 8 +
                    3 * _eccSquared * _eccSquared / 32 +
                    45 * _eccSquared * _eccSquared * _eccSquared / 1024) *
                sin(2 * latRad) +
            (15 * _eccSquared * _eccSquared / 256 +
                    45 * _eccSquared * _eccSquared * _eccSquared / 1024) *
                sin(4 * latRad) -
            (35 * _eccSquared * _eccSquared * _eccSquared / 3072) *
                sin(6 * latRad));

    final leste = _k0 *
            n *
            (aCoef +
                (1 - t + c) * pow(aCoef, 3) / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * eccPrimeSquared) *
                    pow(aCoef, 5) /
                    120) +
        500000.0;

    var norte = _k0 *
        (m +
            n *
                tanLat *
                (aCoef * aCoef / 2 +
                    (5 - t + 9 * c + 4 * c * c) * pow(aCoef, 4) / 24 +
                    (61 - 58 * t + t * t + 600 * c - 330 * eccPrimeSquared) *
                        pow(aCoef, 6) /
                        720));

    final hemisferioSul = latitude < 0;
    if (hemisferioSul) {
      norte += 10000000.0; // falso norte do hemisfério sul
    }

    return CoordenadaUtm(
      leste: leste,
      norte: norte,
      zona: zona,
      hemisferioSul: hemisferioSul,
    );
  }

  /// WKT ESRI da projeção UTM/WGS84 para a zona informada, usado no .prj.
  static String wktParaZona(int zona, bool hemisferioSul) {
    final hemisferioLetra = hemisferioSul ? 'S' : 'N';
    final falsoNorte = hemisferioSul ? ',PARAMETER["False_Northing",10000000.0]' : '';
    final meridianoCentral = (zona - 1) * 6 - 180 + 3;
    return 'PROJCS["WGS_1984_UTM_Zone_$zona$hemisferioLetra",'
        'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",'
        'SPHEROID["WGS_1984",6378137.0,298.257223563]],'
        'PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],'
        'PROJECTION["Transverse_Mercator"],'
        'PARAMETER["False_Easting",500000.0]$falsoNorte,'
        'PARAMETER["Central_Meridian",$meridianoCentral.0],'
        'PARAMETER["Scale_Factor",0.9996],'
        'PARAMETER["Latitude_Of_Origin",0.0],'
        'UNIT["Meter",1.0]]';
  }
}
