import 'dart:io';
import 'package:dart_shp/dart_shp.dart';
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../diagnostico/data/models/leitura_model.dart';
import 'dose_service.dart';
import 'utm_converter.dart';

class ShapefileExportService {
  final DoseService _doseService = DoseService();
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

    // O monitor de taxa variável espera o shapefile projetado em metros
    // (UTM), não em graus decimais — senão a escala fica errada. A zona é
    // calculada a partir do primeiro ponto (as leituras de um mesmo envio
    // ficam tipicamente dentro da mesma zona UTM).
    final zona = leituras.isNotEmpty
        ? UtmConverter.zonaUtm(leituras.first.longitude)
        : 22;
    final hemisferioSul =
        leituras.isNotEmpty ? leituras.first.latitude < 0 : true;

    await _escreverGeometria(leituras, shpFile, shxFile);
    await _escreverAtributos(leituras, dbfFile);
    prjFile.writeAsStringSync(UtmConverter.wktParaZona(zona, hemisferioSul));

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
    final pontos = leituras.map((l) {
      final utm = UtmConverter.converter(l.latitude, l.longitude);
      return geometryFactory.createPoint(Coordinate.fromYX(utm.leste, utm.norte));
    }).toList();

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
      ..addColumn('DOSE', 'N', 6, 1)
      ..addColumn('REVISAR', 'L', 1, 0)
      ..addColumn('DATA_HORA', 'C', 19, 0)
      ..addColumn('TALHAO', 'C', 30, 0)
      ..addColumn('SYNC', 'L', 1, 0)
      ..setNumRecords(leituras.length);

    final writer = DbaseFileWriter(header, FileWriter(dbfFile));
    await writer.open();

    for (final l in leituras) {
      final dose = _doseService.calcularDose(l.resultadoIA);
      final revisar = _doseService.precisaRevisao(l.resultadoIA, l.confianca);

      await writer.writeRecord([
        l.id,
        l.resultadoIA,
        l.confianca * 100,
        dose,
        revisar,
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
