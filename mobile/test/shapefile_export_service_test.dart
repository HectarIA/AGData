import 'dart:io';

import 'package:dart_shp/dart_shp.dart';
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';
import 'package:mobile/features/exportacao/data/services/shapefile_export_service.dart';

void main() {
  test('exporta leituras e relê o shapefile de volta com valores corretos',
      () async {
    final tempDir = Directory.systemTemp.createTempSync('agdata_shp_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final leituras = [
      LeituraModel()
        ..id = 1
        ..resultadoIA = 'FERRUGEM'
        ..confianca = 0.9321
        ..caminhoImagem = ''
        ..dataHora = DateTime(2026, 9, 30, 14, 5, 30)
        ..latitude = -26.2295
        ..longitude = -51.0871
        ..talhao = 'Lote Sul'
        ..sincronizado = false,
      LeituraModel()
        ..id = 2
        ..resultadoIA = 'SAUDAVEL'
        ..confianca = 0.995
        ..caminhoImagem = ''
        ..dataHora = DateTime(2026, 9, 30, 14, 12, 0)
        ..latitude = -26.2301
        ..longitude = -51.0860
        ..talhao = 'Lote Sul'
        ..sincronizado = true,
    ];

    final arquivos = await ShapefileExportService().exportarLeituras(
      leituras,
      nomeBase: 'teste_agdata',
      diretorio: tempDir,
    );

    // Os 4 arquivos foram criados e não estão vazios.
    expect(arquivos.length, 4);
    for (final f in arquivos) {
      expect(f.existsSync(), isTrue, reason: '${f.path} deveria existir');
      expect(f.lengthSync(), greaterThan(0));
    }

    final prj = arquivos.firstWhere((f) => f.path.endsWith('.prj'));
    expect(prj.readAsStringSync(), contains('WGS_1984'));

    // Relê o .shp/.shx/.dbf de volta com o próprio dart_shp, simulando
    // o que um QGIS ou monitor agrícola faria ao abrir o arquivo.
    final shpFile = arquivos.firstWhere((f) => f.path.endsWith('.shp'));
    final reader = ShapefileFeatureReader(shpFile);
    await reader.open();

    final lidas = <Feature>[];
    while (await reader.hasNext()) {
      lidas.add(await reader.next());
    }
    reader.close();

    expect(lidas.length, 2, reason: 'deveria reler as 2 leituras gravadas');

    final primeira = lidas[0];
    final ponto = primeira.geometry as Point;
    expect(ponto.getY(), closeTo(-26.2295, 0.0001)); // latitude
    expect(ponto.getX(), closeTo(-51.0871, 0.0001)); // longitude

    expect(primeira.attributes['DOENCA'].toString().trim(), 'FERRUGEM');
    expect(primeira.attributes['TALHAO'].toString().trim(), 'Lote Sul');
    expect(
      double.parse(primeira.attributes['CONFIANCA'].toString()),
      closeTo(93.21, 0.01),
    );

    final segunda = lidas[1];
    expect(segunda.attributes['DOENCA'].toString().trim(), 'SAUDAVEL');
  });
}
