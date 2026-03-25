// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leitura_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLeituraModelCollection on Isar {
  IsarCollection<LeituraModel> get leituraModels => this.collection();
}

const LeituraModelSchema = CollectionSchema(
  name: r'LeituraModel',
  id: -8506823472996281174,
  properties: {
    r'caminhoImagem': PropertySchema(
      id: 0,
      name: r'caminhoImagem',
      type: IsarType.string,
    ),
    r'confianca': PropertySchema(
      id: 1,
      name: r'confianca',
      type: IsarType.double,
    ),
    r'dataHora': PropertySchema(
      id: 2,
      name: r'dataHora',
      type: IsarType.dateTime,
    ),
    r'latitude': PropertySchema(
      id: 3,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 4,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'resultadoIA': PropertySchema(
      id: 5,
      name: r'resultadoIA',
      type: IsarType.string,
    ),
    r'sincronizado': PropertySchema(
      id: 6,
      name: r'sincronizado',
      type: IsarType.bool,
    ),
    r'talhao': PropertySchema(
      id: 7,
      name: r'talhao',
      type: IsarType.string,
    )
  },
  estimateSize: _leituraModelEstimateSize,
  serialize: _leituraModelSerialize,
  deserialize: _leituraModelDeserialize,
  deserializeProp: _leituraModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'sincronizado': IndexSchema(
      id: -5635005241243394166,
      name: r'sincronizado',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sincronizado',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _leituraModelGetId,
  getLinks: _leituraModelGetLinks,
  attach: _leituraModelAttach,
  version: '3.1.0+1',
);

int _leituraModelEstimateSize(
  LeituraModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.caminhoImagem.length * 3;
  bytesCount += 3 + object.resultadoIA.length * 3;
  bytesCount += 3 + object.talhao.length * 3;
  return bytesCount;
}

void _leituraModelSerialize(
  LeituraModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.caminhoImagem);
  writer.writeDouble(offsets[1], object.confianca);
  writer.writeDateTime(offsets[2], object.dataHora);
  writer.writeDouble(offsets[3], object.latitude);
  writer.writeDouble(offsets[4], object.longitude);
  writer.writeString(offsets[5], object.resultadoIA);
  writer.writeBool(offsets[6], object.sincronizado);
  writer.writeString(offsets[7], object.talhao);
}

LeituraModel _leituraModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LeituraModel();
  object.caminhoImagem = reader.readString(offsets[0]);
  object.confianca = reader.readDouble(offsets[1]);
  object.dataHora = reader.readDateTime(offsets[2]);
  object.id = id;
  object.latitude = reader.readDouble(offsets[3]);
  object.longitude = reader.readDouble(offsets[4]);
  object.resultadoIA = reader.readString(offsets[5]);
  object.sincronizado = reader.readBool(offsets[6]);
  object.talhao = reader.readString(offsets[7]);
  return object;
}

P _leituraModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _leituraModelGetId(LeituraModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _leituraModelGetLinks(LeituraModel object) {
  return [];
}

void _leituraModelAttach(
    IsarCollection<dynamic> col, Id id, LeituraModel object) {
  object.id = id;
}

extension LeituraModelQueryWhereSort
    on QueryBuilder<LeituraModel, LeituraModel, QWhere> {
  QueryBuilder<LeituraModel, LeituraModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhere> anySincronizado() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sincronizado'),
      );
    });
  }
}

extension LeituraModelQueryWhere
    on QueryBuilder<LeituraModel, LeituraModel, QWhereClause> {
  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause>
      sincronizadoEqualTo(bool sincronizado) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sincronizado',
        value: [sincronizado],
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterWhereClause>
      sincronizadoNotEqualTo(bool sincronizado) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sincronizado',
              lower: [],
              upper: [sincronizado],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sincronizado',
              lower: [sincronizado],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sincronizado',
              lower: [sincronizado],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sincronizado',
              lower: [],
              upper: [sincronizado],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LeituraModelQueryFilter
    on QueryBuilder<LeituraModel, LeituraModel, QFilterCondition> {
  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caminhoImagem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'caminhoImagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'caminhoImagem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caminhoImagem',
        value: '',
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      caminhoImagemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'caminhoImagem',
        value: '',
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      confiancaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confianca',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      confiancaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confianca',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      confiancaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confianca',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      confiancaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confianca',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      dataHoraEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataHora',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      dataHoraGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dataHora',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      dataHoraLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dataHora',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      dataHoraBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dataHora',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      latitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      latitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      latitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      latitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      longitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      longitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      longitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      longitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIALessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIABetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resultadoIA',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'resultadoIA',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'resultadoIA',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resultadoIA',
        value: '',
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      resultadoIAIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'resultadoIA',
        value: '',
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      sincronizadoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sincronizado',
        value: value,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> talhaoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> talhaoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'talhao',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'talhao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition> talhaoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'talhao',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'talhao',
        value: '',
      ));
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterFilterCondition>
      talhaoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'talhao',
        value: '',
      ));
    });
  }
}

extension LeituraModelQueryObject
    on QueryBuilder<LeituraModel, LeituraModel, QFilterCondition> {}

extension LeituraModelQueryLinks
    on QueryBuilder<LeituraModel, LeituraModel, QFilterCondition> {}

extension LeituraModelQuerySortBy
    on QueryBuilder<LeituraModel, LeituraModel, QSortBy> {
  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByCaminhoImagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caminhoImagem', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      sortByCaminhoImagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caminhoImagem', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByConfianca() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confianca', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByConfiancaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confianca', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByDataHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHora', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByDataHoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHora', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByResultadoIA() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultadoIA', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      sortByResultadoIADesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultadoIA', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortBySincronizado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sincronizado', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      sortBySincronizadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sincronizado', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByTalhao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'talhao', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> sortByTalhaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'talhao', Sort.desc);
    });
  }
}

extension LeituraModelQuerySortThenBy
    on QueryBuilder<LeituraModel, LeituraModel, QSortThenBy> {
  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByCaminhoImagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caminhoImagem', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      thenByCaminhoImagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caminhoImagem', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByConfianca() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confianca', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByConfiancaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confianca', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByDataHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHora', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByDataHoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHora', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByResultadoIA() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultadoIA', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      thenByResultadoIADesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultadoIA', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenBySincronizado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sincronizado', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy>
      thenBySincronizadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sincronizado', Sort.desc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByTalhao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'talhao', Sort.asc);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QAfterSortBy> thenByTalhaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'talhao', Sort.desc);
    });
  }
}

extension LeituraModelQueryWhereDistinct
    on QueryBuilder<LeituraModel, LeituraModel, QDistinct> {
  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByCaminhoImagem(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caminhoImagem',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByConfianca() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confianca');
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByDataHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataHora');
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByResultadoIA(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resultadoIA', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctBySincronizado() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sincronizado');
    });
  }

  QueryBuilder<LeituraModel, LeituraModel, QDistinct> distinctByTalhao(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'talhao', caseSensitive: caseSensitive);
    });
  }
}

extension LeituraModelQueryProperty
    on QueryBuilder<LeituraModel, LeituraModel, QQueryProperty> {
  QueryBuilder<LeituraModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LeituraModel, String, QQueryOperations> caminhoImagemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caminhoImagem');
    });
  }

  QueryBuilder<LeituraModel, double, QQueryOperations> confiancaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confianca');
    });
  }

  QueryBuilder<LeituraModel, DateTime, QQueryOperations> dataHoraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataHora');
    });
  }

  QueryBuilder<LeituraModel, double, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<LeituraModel, double, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<LeituraModel, String, QQueryOperations> resultadoIAProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resultadoIA');
    });
  }

  QueryBuilder<LeituraModel, bool, QQueryOperations> sincronizadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sincronizado');
    });
  }

  QueryBuilder<LeituraModel, String, QQueryOperations> talhaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'talhao');
    });
  }
}
