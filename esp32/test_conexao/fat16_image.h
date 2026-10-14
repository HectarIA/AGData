#pragma once
#include <Arduino.h>

// Disco FAT16 construído inteiramente em RAM (PSRAM), usado como backend
// do dispositivo USB Mass Storage. Sempre que novos arquivos chegam via
// Wi-Fi, a imagem inteira é reconstruída do zero — não há alocador de
// espaço livre, cada chamada começa limpa.

bool fat16_init();

// shp/shx/dbf/prj: ponteiro + tamanho de cada arquivo do shapefile.
// Um ponteiro nulo (ou tamanho 0) grava um arquivo vazio.
bool fat16_build(const uint8_t *shp, size_t shpLen, const uint8_t *shx, size_t shxLen, const uint8_t *dbf, size_t dbfLen, const uint8_t *prj, size_t prjLen);

uint8_t *fat16_disk();
uint32_t fat16_sector_count();
uint16_t fat16_sector_size();
