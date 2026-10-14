#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <SPIFFS.h>
#include "USB.h"
#include "USBMSC.h"
#include "esp_heap_caps.h"
#include "fat16_image.h"

const char *AP_SSID = "AGData-ESP32";
const char *AP_PASSWORD = "agdata123";

WebServer server(80);
USBMSC MSC;

// --- Buffers de recepção dos 4 arquivos do shapefile (PSRAM) ---
constexpr size_t MAX_FILE_SIZE = 256 * 1024;

uint8_t *bufShp = nullptr, *bufShx = nullptr, *bufDbf = nullptr, *bufPrj = nullptr;
size_t lenShp = 0, lenShx = 0, lenDbf = 0, lenPrj = 0;

uint8_t *alocarBufferArquivo() {
  return (uint8_t *)heap_caps_malloc(MAX_FILE_SIZE, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
}

// ---------------- Persistência em flash (sobrevive a quedas de energia) ----------------
// A imagem FAT16 em si vive só na PSRAM (perdida em qualquer reset), mas os
// 4 arquivos crus ficam salvos na flash (SPIFFS) pra poder reconstruir a
// imagem no boot sem precisar que o celular mande tudo de novo.

const char *CAMINHO_SHP = "/last.shp";
const char *CAMINHO_SHX = "/last.shx";
const char *CAMINHO_DBF = "/last.dbf";
const char *CAMINHO_PRJ = "/last.prj";

void salvarArquivoNaFlash(const char *caminho, const uint8_t *dados, size_t tamanho) {
  File f = SPIFFS.open(caminho, FILE_WRITE);
  if (!f) return;
  if (tamanho > 0 && dados != nullptr) {
    f.write(dados, tamanho);
  }
  f.close();
}

void salvarShapefileNaFlash() {
  salvarArquivoNaFlash(CAMINHO_SHP, bufShp, lenShp);
  salvarArquivoNaFlash(CAMINHO_SHX, bufShx, lenShx);
  salvarArquivoNaFlash(CAMINHO_DBF, bufDbf, lenDbf);
  salvarArquivoNaFlash(CAMINHO_PRJ, bufPrj, lenPrj);
}

// Lê um arquivo salvo pra dentro do buffer já alocado (até MAX_FILE_SIZE) e
// devolve quantos bytes foram lidos (0 se o arquivo não existir).
size_t carregarArquivoDaFlash(const char *caminho, uint8_t *buf) {
  if (!SPIFFS.exists(caminho)) return 0;
  File f = SPIFFS.open(caminho, FILE_READ);
  if (!f) return 0;
  size_t tamanho = f.size();
  if (tamanho > MAX_FILE_SIZE) tamanho = MAX_FILE_SIZE;
  size_t lido = tamanho > 0 ? f.read(buf, tamanho) : 0;
  f.close();
  return lido;
}

// Tenta recarregar o último shapefile salvo na flash pros buffers em
// PSRAM. Retorna true se havia algo salvo (mesmo que parcialmente vazio).
bool carregarShapefileDaFlash() {
  if (!SPIFFS.exists(CAMINHO_SHP)) return false;
  lenShp = carregarArquivoDaFlash(CAMINHO_SHP, bufShp);
  lenShx = carregarArquivoDaFlash(CAMINHO_SHX, bufShx);
  lenDbf = carregarArquivoDaFlash(CAMINHO_DBF, bufDbf);
  lenPrj = carregarArquivoDaFlash(CAMINHO_PRJ, bufPrj);
  return true;
}

// ---------------- USB Mass Storage (pendrive virtual) ----------------

int32_t onMscRead(uint32_t lba, uint32_t offset, void *buffer, uint32_t bufsize) {
  uint8_t *disco = fat16_disk();
  if (!disco) return -1;
  memcpy(buffer, disco + (size_t)lba * fat16_sector_size() + offset, bufsize);
  return bufsize;
}

int32_t onMscWrite(uint32_t lba, uint32_t offset, uint8_t *buffer, uint32_t bufsize) {
  uint8_t *disco = fat16_disk();
  if (!disco) return -1;
  memcpy(disco + (size_t)lba * fat16_sector_size() + offset, buffer, bufsize);
  return bufsize;
}

bool onMscStartStop(uint8_t power_condition, bool start, bool load_eject) {
  return true;
}

void configurarUsbMsc() {
  MSC.vendorID("AGData");
  MSC.productID("Pulverizador");
  MSC.productRevision("1.0");
  MSC.onRead(onMscRead);
  MSC.onWrite(onMscWrite);
  MSC.onStartStop(onMscStartStop);
  MSC.mediaPresent(true);
  MSC.isWritable(true);
  MSC.begin(fat16_sector_count(), fat16_sector_size());
  USB.begin();
}

// ---------------- Rotas HTTP ----------------

void handleRoot() {
  IPAddress ip = WiFi.softAPIP();
  String status = "AGData ESP32 online. IP: " + ip.toString() +
                   " | Clientes conectados: " + String(WiFi.softAPgetStationNum()) +
                   " | Ultimo shapefile: SHP=" + String(lenShp) + "b SHX=" + String(lenShx) +
                   "b DBF=" + String(lenDbf) + "b PRJ=" + String(lenPrj) + "b";
  server.send(200, "text/plain", status);
}

// Endpoint legado de debug: recebe um JSON simples e só imprime no Serial.
void handleUploadJson() {
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"erro\":\"corpo vazio\"}");
    return;
  }

  String corpo = server.arg("plain");
  JsonDocument doc;
  DeserializationError erro = deserializeJson(doc, corpo);
  if (erro) {
    server.send(400, "application/json", "{\"erro\":\"json invalido\"}");
    return;
  }

  JsonArray leituras = doc.as<JsonArray>();
  Serial.println("===== Leituras recebidas (debug JSON) =====");
  Serial.printf("Total: %d\n", leituras.size());
  for (JsonObject l : leituras) {
    const char *doenca = l["resultadoIA"] | "?";
    float confianca = l["confianca"] | 0.0f;
    const char *talhao = l["talhao"] | "?";
    double lat = l["latitude"] | 0.0;
    double lon = l["longitude"] | 0.0;
    Serial.printf("- %s (%.1f%%) | talhao=%s | lat=%.6f lon=%.6f\n", doenca, confianca * 100, talhao, lat, lon);
  }
  Serial.println("=============================================");

  String resposta = "{\"status\":\"ok\",\"recebidas\":" + String(leituras.size()) + "}";
  server.send(200, "application/json", resposta);
}

// Recebe os 4 arquivos do shapefile (multipart/form-data, campos "shp",
// "shx", "dbf", "prj") e grava cada parte no buffer correspondente.
void handleShapefileUploadPart() {
  HTTPUpload &upload = server.upload();

  uint8_t *buf = nullptr;
  size_t *len = nullptr;

  if (upload.name == "shp") {
    buf = bufShp;
    len = &lenShp;
  } else if (upload.name == "shx") {
    buf = bufShx;
    len = &lenShx;
  } else if (upload.name == "dbf") {
    buf = bufDbf;
    len = &lenDbf;
  } else if (upload.name == "prj") {
    buf = bufPrj;
    len = &lenPrj;
  } else {
    return;
  }

  if (!buf) return;

  if (upload.status == UPLOAD_FILE_START) {
    *len = 0;
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (*len + upload.currentSize <= MAX_FILE_SIZE) {
      memcpy(buf + *len, upload.buf, upload.currentSize);
      *len += upload.currentSize;
    }
  }
}

// Chamado depois que todas as partes do multipart já foram recebidas.
void handleShapefileUploadDone() {
  bool ok = fat16_build(bufShp, lenShp, bufShx, lenShx, bufDbf, lenDbf, bufPrj, lenPrj);

  if (ok) {
    Serial.printf("Shapefile atualizado no pendrive: SHP=%ub SHX=%ub DBF=%ub PRJ=%ub\n", (unsigned)lenShp, (unsigned)lenShx, (unsigned)lenDbf, (unsigned)lenPrj);
    salvarShapefileNaFlash();
    server.send(200, "application/json", "{\"status\":\"ok\"}");
  } else {
    server.send(500, "application/json", "{\"erro\":\"falha ao gravar imagem\"}");
  }

  if (ok) {
    // Sinaliza "mídia removida/inserida" pro host perceber a troca sem
    // precisar desconectar o cabo fisicamente — mesmo princípio de trocar
    // um cartão SD num leitor USB sem tirar o leitor da porta. Não há
    // garantia de que todo host reaja a isso automaticamente (depende do
    // software de quem está lendo), mas é o mecanismo padrão pra isso.
    MSC.mediaPresent(false);
    delay(50);
    MSC.mediaPresent(true);
  }
}

void handleNotFound() {
  server.send(404, "text/plain", "Rota nao encontrada");
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  fat16_init();

  bufShp = alocarBufferArquivo();
  bufShx = alocarBufferArquivo();
  bufDbf = alocarBufferArquivo();
  bufPrj = alocarBufferArquivo();

  bool temDadosSalvos = false;
  if (SPIFFS.begin(true)) {
    temDadosSalvos = carregarShapefileDaFlash();
  }

  if (temDadosSalvos) {
    fat16_build(bufShp, lenShp, bufShx, lenShx, bufDbf, lenDbf, bufPrj, lenPrj);
  } else {
    fat16_build(nullptr, 0, nullptr, 0, nullptr, 0, nullptr, 0);  // nada salvo ainda: imagem vazia, porém válida
  }

  configurarUsbMsc();

  WiFi.softAP(AP_SSID, AP_PASSWORD);
  IPAddress ip = WiFi.softAPIP();

  Serial.println();
  Serial.println("===== AGData ESP32 =====");
  Serial.print("Rede WiFi criada: ");
  Serial.println(AP_SSID);
  Serial.print("IP do servidor: ");
  Serial.println(ip);
  Serial.println("POST /upload           -> debug JSON (Serial)");
  Serial.println("POST /upload-shapefile -> grava shapefile no pendrive USB");
  Serial.println("=========================");

  server.on("/", HTTP_GET, handleRoot);
  server.on("/upload", HTTP_POST, handleUploadJson);
  server.on("/upload-shapefile", HTTP_POST, handleShapefileUploadDone, handleShapefileUploadPart);
  server.onNotFound(handleNotFound);
  server.begin();
}

void loop() {
  server.handleClient();
}
