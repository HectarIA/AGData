import 'dart:io';
import 'package:dart_shp/dart_shp.dart';
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../diagnostico/data/models/leitura_model.dart';

// WKT ESRI padrão para WGS84 (EPSG:4326) — mesmo datum usado pelo GPS do
// telemóvel, necessário para o .prj do shapefile ser lido corretamente
// em QGIS e nos monitores de agricultura de precisão.
const String _wgs84Wkt = 'GEOGCS["GCS_WGS_1984",'
    'DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],'
    'PRIMEM["Greenwich",0.0],'
    'UNIT["Degree",0.0174532925199433]]';

class ShapefileExportService {
  Future<List<File>> exportarLeituras(
    List<LeituraModel> leituras, {
    required String nomeBase,
    Directory? diretorio,
  }) async {
    final exportDir = diretorio ??
        Directory(
            '${(await getApplicationDocumentsDirectory()).path}/exportacoes');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final shpFile = File('${exportDir.path}/$nomeBase.shp');
    final shxFile = File('${exportDir.path}/$nomeBase.shx');
    final dbfFile = File('${exportDir.path}/$nomeBase.dbf');
    final prjFile = File('${exportDir.path}/$nomeBase.prj');

    await _escreverGeometria(leituras, shpFile, shxFile);
    await _escreverAtributos(leituras, dbfFile);
    prjFile.writeAsStringSync(_wgs84Wkt);

    return [shpFile, shxFile, dbfFile, prjFile];
  }

  Future<void> compartilharArquivos(
    List<File> arquivos, {
    required String assunto,
  }) async {
    final xFiles = arquivos.map((f) => XFile(f.path)).toList();
    await SharePlus.instance.share(
      ShareParams(files: xFiles, subject: assunto),
    );
  }

  Future<void> _escreverGeometria(
    List<LeituraModel> leituras,
    File shpFile,
    File shxFile,
  ) async {
    final geometryFactory = GeometryFactory.defaultPrecision();
    final pontos = leituras
        .map((l) =>
            geometryFactory.createPoint(Coordinate.fromYX(l.latitude, l.longitude)))
        .toList();

    final shpWriter = FileWriter(shpFile);
    final shxWriter = FileWriter(shxFile);
    final writer = PointWriter(pontos, ShapeType.POINT);
    await writer.write(shpWriter, shxWriter);
    shpWriter.close();
    shxWriter.close();
  }

  Future<void> _escreverAtributos(
    List<LeituraModel> leituras,
    File dbfFile,
  ) async {
    final header = DbaseFileHeader()
      ..addColumn('ID', 'N', 10, 0)
      ..addColumn('DOENCA', 'C', 20, 0)
      ..addColumn('CONFIANCA', 'N', 6, 2)
      ..addColumn('DATA_HORA', 'C', 19, 0)
      ..addColumn('TALHAO', 'C', 30, 0)
      ..addColumn('SYNC', 'L', 1, 0)
      ..setNumRecords(leituras.length);

    final writer = DbaseFileWriter(header, FileWriter(dbfFile));
    await writer.open();

    for (final l in leituras) {
      await writer.writeRecord([
        l.id,
        l.resultadoIA,
        l.confianca * 100,
        _formatarDataHora(l.dataHora),
        l.talhao,
        l.sincronizado,
      ]);
    }

    writer.close();
  }

  String _formatarDataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${dois(d.month)}-${dois(d.day)} '
        '${dois(d.hour)}:${dois(d.minute)}:${dois(d.second)}';
  }
}
