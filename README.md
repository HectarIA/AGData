# 🌱 AI Agro - Classificador de Doenças da Soja

Um aplicativo móvel desenvolvido em Flutter que utiliza Inteligência Artificial (Visão Computacional) rodando localmente (offline) para identificar doenças em folhas de soja diretamente do campo.

## 📱 Sobre o Projeto
O objetivo deste aplicativo é auxiliar produtores rurais e agrônomos na identificação rápida de fitopatologias na cultura da soja. Ao tirar uma foto da folha, o aplicativo redimensiona a imagem, processa através de um modelo TensorFlow Lite embarcado e retorna a probabilidade da doença em segundos.

O app também captura a geolocalização (Latitude/Longitude) do diagnóstico para futuro armazenamento em nuvem.

## 🎯 Doenças Identificadas (Classes do Modelo)
Atualmente, a IA está treinada para reconhecer os seguintes cenários:
* ✅ **Ferrugem Asiática** (*Phakopsora pachyrhizi*)
* ✅ **Mancha Alvo** (*Corynespora cassiicola*)
* ✅ **Oídio** (*Microsphaera diffusa*)
* ✅ **Saudável** (Ausência de lesões)
* 🚧 **Mancha Parda** (*Septoria glycines*) - *Em fase de coleta de imagens de campo (in-situ) e treinamento.*

## 🛠️ Tecnologias Utilizadas
**Mobile (Front-end & Lógica):**
* Flutter / Dart
* Câmera e Processamento de Imagem (pacote `image` para redimensionamento 224x224)
* Integração com TFLite (TensorFlow Lite)
* Geolocalização (Lat/Lng)

**Inteligência Artificial (Back-end de Treinamento):**
* Python
* TensorFlow / Keras (Treinamento do modelo de classificação de imagens)
* Data Augmentation (ImageDataGenerator) para robustez de cenário real
* OpenCV (Extração de frames de vídeos in-situ)

**Banco de Dados (Em breve):**
* Firebase Cloud Firestore (NoSQL) para histórico de diagnósticos.

## 🚀 Status Atual
- [x] Captura de imagens via câmera/galeria.
- [x] Integração do modelo `.tflite`.
- [x] Tratamento de Array e extração de porcentagens de acerto.
- [x] Coleta de coordenadas GPS.
- [ ] Integração com Firebase para salvar histórico.
- [ ] Refinamento do dataset com imagens reais "de campo" (redução de falsos positivos).