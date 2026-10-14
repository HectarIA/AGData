#include "fat16_image.h"
#include "esp_heap_caps.h"
#include <string.h>

namespace {

constexpr uint16_t SECTOR_SIZE = 512;
constexpr uint32_t TOTAL_SECTORS = 8192;  // 4 MB no total
constexpr uint8_t NUM_FATS = 2;
constexpr uint16_t ROOT_ENTRIES = 16;
constexpr uint8_t SECTORS_PER_CLUSTER = 1;
constexpr uint16_t SECTORS_PER_FAT = 32;
constexpr uint16_t RESERVED_SECTORS = 1;

// Pré-calculado para TOTAL_SECTORS=8192 com os parâmetros acima:
// root_dir = 1 setor, data = 8192 - 1 - 32*2 - 1 = 8126 clusters.
// 8126 está dentro da faixa válida de FAT16 ([4085, 65525)).
constexpr uint32_t ROOT_DIR_SECTORS = (ROOT_ENTRIES * 32 + SECTOR_SIZE - 1) / SECTOR_SIZE;
constexpr uint32_t FIRST_FAT_SECTOR = RESERVED_SECTORS;
constexpr uint32_t FIRST_ROOT_SECTOR = FIRST_FAT_SECTOR + (uint32_t)NUM_FATS * SECTORS_PER_FAT;
constexpr uint32_t FIRST_DATA_SECTOR = FIRST_ROOT_SECTOR + ROOT_DIR_SECTORS;

// Data fixa (01/01/2024) usada nos metadados dos arquivos — o ESP32 não
// tem RTC com hora real disponível aqui, e a data exata não importa pro
// funcionamento, só precisa ser um valor válido no formato FAT.
constexpr uint16_t FAT_DATE_FIXO = (44 << 9) | (1 << 5) | 1;  // ano-1980=44, mes=1, dia=1

uint8_t *g_disk = nullptr;

inline void putU16(uint8_t *p, uint16_t v) {
  p[0] = v & 0xFF;
  p[1] = (v >> 8) & 0xFF;
}

inline void putU32(uint8_t *p, uint32_t v) {
  p[0] = v & 0xFF;
  p[1] = (v >> 8) & 0xFF;
  p[2] = (v >> 16) & 0xFF;
  p[3] = (v >> 24) & 0xFF;
}

inline uint8_t *sectorPtr(uint32_t sector) {
  return g_disk + (size_t)sector * SECTOR_SIZE;
}

void writeBootSector() {
  uint8_t *b = sectorPtr(0);
  memset(b, 0, SECTOR_SIZE);

  b[0] = 0xEB;
  b[1] = 0x3C;
  b[2] = 0x90;
  memcpy(b + 3, "MSDOS5.0", 8);
  putU16(b + 0x0B, SECTOR_SIZE);
  b[0x0D] = SECTORS_PER_CLUSTER;
  putU16(b + 0x0E, RESERVED_SECTORS);
  b[0x10] = NUM_FATS;
  putU16(b + 0x11, ROOT_ENTRIES);
  putU16(b + 0x13, (uint16_t)TOTAL_SECTORS);
  b[0x15] = 0xF8;  // mídia: disco fixo
  putU16(b + 0x16, SECTORS_PER_FAT);
  putU16(b + 0x18, 32);  // setores por trilha (dummy, sem geometria real)
  putU16(b + 0x1A, 2);   // cabeças (dummy)
  putU32(b + 0x1C, 0);   // setores ocultos
  putU32(b + 0x20, 0);   // total_sectors_32 (não usado, cabe em 16 bits)
  b[0x24] = 0x80;        // número da unidade
  b[0x25] = 0;
  b[0x26] = 0x29;  // assinatura de boot estendida
  putU32(b + 0x27, 0x41474441);
  memcpy(b + 0x2B, "AGDATA     ", 11);
  memcpy(b + 0x36, "FAT16   ", 8);
  b[0x1FE] = 0x55;
  b[0x1FF] = 0xAA;
}

void writeFats() {
  for (int f = 0; f < NUM_FATS; f++) {
    uint8_t *fat = sectorPtr(FIRST_FAT_SECTOR + (uint32_t)f * SECTORS_PER_FAT);
    memset(fat, 0, (size_t)SECTORS_PER_FAT * SECTOR_SIZE);
    putU16(fat + 0, 0xFFF8);
    putU16(fat + 2, 0xFFFF);
  }
}

void setFatEntry(uint16_t cluster, uint16_t value) {
  for (int f = 0; f < NUM_FATS; f++) {
    uint8_t *fat = sectorPtr(FIRST_FAT_SECTOR + (uint32_t)f * SECTORS_PER_FAT);
    putU16(fat + (size_t)cluster * 2, value);
  }
}

void setFatChain(uint16_t startCluster, uint16_t clusterCount) {
  for (uint16_t i = 0; i < clusterCount; i++) {
    uint16_t cluster = startCluster + i;
    uint16_t value = (i == clusterCount - 1) ? 0xFFFF : (uint16_t)(cluster + 1);
    setFatEntry(cluster, value);
  }
}

uint32_t clusterToSector(uint16_t cluster) {
  return FIRST_DATA_SECTOR + (uint32_t)(cluster - 2) * SECTORS_PER_CLUSTER;
}

void nameToFat8_3(const char *base, const char *ext, char out[11]) {
  memset(out, ' ', 11);
  size_t bl = strlen(base);
  if (bl > 8) bl = 8;
  memcpy(out, base, bl);
  size_t el = strlen(ext);
  if (el > 3) el = 3;
  memcpy(out + 8, ext, el);
}

void writeDirEntry(int index, const char name8_3[11], uint32_t fileSize, uint16_t startCluster, bool isVolumeLabel) {
  uint8_t *root = sectorPtr(FIRST_ROOT_SECTOR);
  uint8_t *e = root + (size_t)index * 32;
  memset(e, 0, 32);
  memcpy(e, name8_3, 11);
  e[11] = isVolumeLabel ? 0x08 : 0x20;  // ATTR_VOLUME_ID ou ATTR_ARCHIVE
  putU16(e + 14, 0x0000);               // hora de criação
  putU16(e + 16, FAT_DATE_FIXO);        // data de criação
  putU16(e + 18, FAT_DATE_FIXO);        // data de último acesso
  putU16(e + 20, 0x0000);               // cluster alto (sempre 0 em FAT16)
  putU16(e + 22, 0x0000);               // hora de modificação
  putU16(e + 24, FAT_DATE_FIXO);        // data de modificação
  putU16(e + 26, startCluster);
  putU32(e + 28, fileSize);
}

// Grava os bytes do arquivo a partir de startCluster e retorna quantos
// clusters foram efetivamente usados (0 se o arquivo estiver vazio).
uint16_t writeFileData(uint16_t startCluster, const uint8_t *data, size_t len) {
  if (len == 0 || data == nullptr) return 0;

  uint16_t clustersNeeded = (uint16_t)((len + SECTOR_SIZE - 1) / SECTOR_SIZE);
  size_t remaining = len;
  const uint8_t *src = data;

  for (uint16_t i = 0; i < clustersNeeded; i++) {
    uint8_t *dst = sectorPtr(clusterToSector(startCluster + i));
    size_t chunk = remaining < SECTOR_SIZE ? remaining : SECTOR_SIZE;
    if (chunk > 0) memcpy(dst, src, chunk);
    if (chunk < SECTOR_SIZE) memset(dst + chunk, 0, SECTOR_SIZE - chunk);
    src += chunk;
    remaining -= chunk;
  }

  setFatChain(startCluster, clustersNeeded);
  return clustersNeeded;
}

}  // namespace

bool fat16_init() {
  if (g_disk) return true;
  size_t total = (size_t)TOTAL_SECTORS * SECTOR_SIZE;
  g_disk = (uint8_t *)heap_caps_malloc(total, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
  return g_disk != nullptr;
}

bool fat16_build(const uint8_t *shp, size_t shpLen, const uint8_t *shx, size_t shxLen, const uint8_t *dbf, size_t dbfLen, const uint8_t *prj, size_t prjLen) {
  if (!g_disk && !fat16_init()) return false;

  memset(g_disk, 0, (size_t)TOTAL_SECTORS * SECTOR_SIZE);
  writeBootSector();
  writeFats();

  char volName[11];
  memcpy(volName, "AGDATA     ", 11);
  writeDirEntry(0, volName, 0, 0, true);

  struct FileSpec {
    const char *base;
    const char *ext;
    const uint8_t *data;
    size_t len;
  };
  FileSpec files[4] = {
    {"AGDATA", "SHP", shp, shpLen},
    {"AGDATA", "SHX", shx, shxLen},
    {"AGDATA", "DBF", dbf, dbfLen},
    {"AGDATA", "PRJ", prj, prjLen},
  };

  uint16_t nextCluster = 2;
  for (int i = 0; i < 4; i++) {
    char name[11];
    nameToFat8_3(files[i].base, files[i].ext, name);

    uint16_t startCluster = files[i].len > 0 ? nextCluster : 0;
    uint16_t used = writeFileData(startCluster, files[i].data, files[i].len);
    writeDirEntry(1 + i, name, (uint32_t)files[i].len, startCluster, false);
    nextCluster += used;
  }

  return true;
}

uint8_t *fat16_disk() { return g_disk; }
uint32_t fat16_sector_count() { return TOTAL_SECTORS; }
uint16_t fat16_sector_size() { return SECTOR_SIZE; }
