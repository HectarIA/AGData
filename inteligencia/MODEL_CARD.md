
# 🧠 Model Card: Classificador de Doenças da Soja

## 1. Detalhes do Modelo
* **Nome do Modelo:** AGdata Soybean Classifier
* **Versão:** 2.0 (Multi-classe)
* **Data da Compilação:** Fevereiro de 2026
* **Arquitetura Base:** MobileNetV2 (com pesos pré-treinados da ImageNet)
* **Otimização para Edge:** TensorFlow Lite Converter com Quantização Padrão (Float32 -> Int8/Float16).

## 2. Casos de Uso Pretendidos
* **Uso Primário:** Identificação rápida de patologias em folhas de soja (*Glycine max*) no campo através de dispositivos móveis.
* **Limitações:** O modelo foi treinado com folhas individuais isoladas; pode apresentar menor precisão caso a foto contenha múltiplas folhas sobrepostas ou elevado ruído de fundo (solo, botas, trator).

## 3. Dados de Treino (Dataset)
* **Volume Total:** 5.415 imagens.
* **Divisão (Split):** 4.333 (Treino / 80%) e 1.082 (Validação / 20%).
* **Classes Detectadas (4):**
  1. `Ferrugem` (Phakopsora pachyrhizi)
  2. `Mancha Alvo` (Corynespora cassiicola)
  3. `Oídio` (Microsphaera diffusa)
  4. `Saudável` (Controlo)
* **Engenharia de Dados (Data Augmentation):** Aplicadas rotações, zoom, inversão horizontal (flip) e *shear* através do Keras `ImageDataGenerator` para combater o *overfitting* e simular condições reais de luminosidade e ângulos.

## 4. Métricas de Avaliação
*(Valores obtidos no final do Fine-Tuning)*
* **Acurácia de Treino:** [ X ] %
* **Acurácia de Validação:** [ X ] %
* **Loss Final (Categorical Crossentropy):** [ X ]

## 5. Implementação (Edge)
* O ficheiro exportado (`modelo_soja_quantizado.tflite`) consome menos de 10 MB de memória RAM no telemóvel do utilizador, garantindo compatibilidade com dispositivos Android de baixa gama e poupança de bateria.