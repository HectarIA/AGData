import tensorflow as tf
import numpy as np
from pathlib import Path
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input
from tensorflow.keras.layers import (
    Dense, GlobalAveragePooling2D, GlobalMaxPooling2D,
    Dropout, Input, Concatenate, BatchNormalization
)
from tensorflow.keras.models import Model

# =============================================================================
# CONFIGURAÇÕES — ajuste apenas estas variáveis se necessário
# =============================================================================
MODELO_ENTRADA  = "modelo_soja_final.keras"
MODELO_TFLITE   = "modelo_soja_v6.tflite"
LABELS_ENTRADA  = "labels.txt"
LABELS_SAIDA    = "labels_v6.txt"
CAMINHO_DATASET = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset_balanceado"
TAMANHO_IMG     = 256
NUM_AMOSTRAS_CALIBRACAO = 150

print("=" * 60)
print("CONVERSOR TFLite — AGdata v6")
print("=" * 60)

# =============================================================================
# PASSO 1 — LÊ AS LABELS para saber num_classes antes de construir o modelo
# =============================================================================
print(f"\n[1/5] Lendo labels: {LABELS_ENTRADA}")

if not Path(LABELS_ENTRADA).exists():
    raise FileNotFoundError(f"Arquivo {LABELS_ENTRADA} não encontrado. "
                            f"Execute o treino.py primeiro.")

with open(LABELS_ENTRADA, 'r') as f:
    class_names = [l.strip() for l in f.readlines() if l.strip()]

num_classes = len(class_names)
print(f"  ✅ {num_classes} classes: {class_names}")

# =============================================================================
# PASSO 2 — RECONSTRÓI A ARQUITETURA DO ZERO
#
# ESTRATÉGIA: em vez de carregar o .keras completo (que falha por causa
# da Lambda layer serializada com preprocess_input fora do escopo),
# reconstruímos a arquitetura idêntica à do treino.py e depois
# carregamos APENAS os pesos do arquivo .keras.
#
# Isso é seguro porque:
# 1. A arquitetura é determinística — mesmos parâmetros = mesmo grafo
# 2. Os pesos são armazenados independentemente da arquitetura no .keras
# 3. O preprocess_input agora é uma camada customizada serializável
#
# A única diferença: a Lambda layer é substituída por
# MobileNetV3Preprocessing — camada customizada que faz a mesma operação
# mas sem depender de escopo de variável no momento da desserialização.
# =============================================================================
print(f"\n[2/5] Reconstruindo arquitetura idêntica ao treino.py v6...")

class MobileNetV3Preprocessing(tf.keras.layers.Layer):
    """
    Substitui a Lambda(preprocess_input) do treino.py.
    Faz exatamente a mesma operação mas é serializável de forma segura
    e não depende de importações no escopo global no momento do load.
    """
    def call(self, inputs):
        return preprocess_input(inputs)

    def get_config(self):
        return super().get_config()

# Constrói a arquitetura — DEVE ser idêntica ao treino.py v6
base_model = MobileNetV3Large(
    weights=None,                            # Sem pesos — serão carregados depois
    include_top=False,
    input_shape=(TAMANHO_IMG, TAMANHO_IMG, 3)
)

inputs   = Input(shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
x_pre    = MobileNetV3Preprocessing(name='mobilenetv3_preprocessing')(inputs)
features = base_model(x_pre, training=False)

gap = GlobalAveragePooling2D(name='gap')(features)
gmp = GlobalMaxPooling2D(name='gmp')(features)
x   = Concatenate(name='dual_pool')([gap, gmp])

x = Dense(512, name='dense_1')(x)
x = BatchNormalization(name='bn_1')(x)
x = tf.keras.layers.Activation('relu', name='relu_1')(x)
x = Dropout(0.4, name='dropout_1')(x)

x = Dense(256, name='dense_2')(x)
x = BatchNormalization(name='bn_2')(x)
x = tf.keras.layers.Activation('relu', name='relu_2')(x)
x = Dropout(0.3, name='dropout_2')(x)

outputs = Dense(num_classes, activation='softmax', dtype='float32', name='classificador')(x)

modelo_reconstruido = Model(inputs, outputs)
print(f"  ✅ Arquitetura reconstruída — {modelo_reconstruido.count_params():,} parâmetros")

# =============================================================================
# PASSO 3 — CARREGA APENAS OS PESOS do arquivo .keras original
#
# O formato .keras armazena pesos e arquitetura separadamente.
# load_weights() acessa apenas a parte de pesos, ignorando completamente
# a Lambda layer problemática e qualquer outro objeto serializado.
# =============================================================================
print(f"\n[3/5] Carregando pesos de: {MODELO_ENTRADA}")

if not Path(MODELO_ENTRADA).exists():
    raise FileNotFoundError(f"Modelo {MODELO_ENTRADA} não encontrado. "
                            f"Execute o treino.py primeiro.")

try:
    modelo_reconstruido.load_weights(MODELO_ENTRADA)
    print("  ✅ Pesos carregados com sucesso")
except Exception as e:
    print(f"  ❌ Erro ao carregar pesos: {e}")
    raise

# Verificação rápida: faz uma inferência em float32 para confirmar
imagem_teste_f32 = np.random.randint(0, 255, (1, TAMANHO_IMG, TAMANHO_IMG, 3)).astype(np.float32)
saida_teste = modelo_reconstruido.predict(imagem_teste_f32, verbose=0)
print(f"  ✅ Inferência de validação OK — shape: {saida_teste.shape} | soma: {saida_teste.sum():.4f}")

# =============================================================================
# PASSO 4 — GERADOR DE CALIBRAÇÃO para quantização INT8
# =============================================================================
print(f"\n[4/5] Preparando calibração INT8 com imagens reais...")

dataset_path = Path(CAMINHO_DATASET)
usa_calibracao = False

if dataset_path.exists():
    extensoes = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}
    todas_imagens = []

    subdirs = [d for d in sorted(dataset_path.iterdir()) if d.is_dir()]
    por_classe = max(1, NUM_AMOSTRAS_CALIBRACAO // len(subdirs))

    for classe_dir in subdirs:
        imgs = [f for f in classe_dir.iterdir() if f.suffix.lower() in extensoes]
        todas_imagens.extend(imgs[:por_classe])

    print(f"  Imagens para calibração: {len(todas_imagens)} "
          f"({por_classe} por classe × {len(subdirs)} classes)")

    def gerador_calibracao():
        for img_path in todas_imagens:
            try:
                img = tf.io.read_file(str(img_path))
                img = tf.image.decode_image(img, channels=3, expand_animations=False)
                img = tf.image.resize(img, [TAMANHO_IMG, TAMANHO_IMG])
                img = tf.cast(img, tf.float32)
                # NÃO aplica preprocess_input aqui — a camada dentro do
                # modelo faz isso automaticamente durante a inferência
                yield [tf.expand_dims(img, 0)]
            except Exception:
                continue

    usa_calibracao = True
    print("  ✅ Gerador de calibração pronto")
else:
    print(f"  ⚠️  Dataset não encontrado: {CAMINHO_DATASET}")
    print("  ℹ️  Prosseguindo com quantização dinâmica (sem calibração INT8 completa)")

# =============================================================================
# PASSO 5 — CONVERSÃO PARA TFLITE
# =============================================================================
print(f"\n[5/5] Convertendo para TFLite...")

converter = tf.lite.TFLiteConverter.from_keras_model(modelo_reconstruido)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

if usa_calibracao:
    converter.representative_dataset  = gerador_calibracao
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        tf.lite.OpsSet.SELECT_TF_OPS       # Fallback para ops não suportadas nativamente
    ]
    converter.inference_input_type  = tf.uint8
    converter.inference_output_type = tf.uint8
    modo_conversao = "INT8 completo com calibração"
else:
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    modo_conversao = "quantização dinâmica (fallback)"

print(f"  Modo: {modo_conversao}")

try:
    tflite_model = converter.convert()
except Exception as e:
    print(f"  ⚠️  Falha na conversão INT8: {e}")
    print("  ℹ️  Tentando fallback com quantização dinâmica...")
    converter_fb = tf.lite.TFLiteConverter.from_keras_model(modelo_reconstruido)
    converter_fb.optimizations = [tf.lite.Optimize.DEFAULT]
    converter_fb.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    tflite_model = converter_fb.convert()
    modo_conversao = "quantização dinâmica (fallback ativado)"

# Salva o .tflite
with open(MODELO_TFLITE, 'wb') as f:
    f.write(tflite_model)

tamanho_mb = len(tflite_model) / (1024 * 1024)
print(f"  ✅ Arquivo salvo: {MODELO_TFLITE} ({tamanho_mb:.2f} MB)")

# Copia labels
import shutil
if Path(LABELS_ENTRADA).exists():
    shutil.copy(LABELS_ENTRADA, LABELS_SAIDA)
    print(f"  ✅ Labels copiadas: {LABELS_SAIDA}")

# =============================================================================
# VALIDAÇÃO FINAL — testa o .tflite gerado com inferência real
# =============================================================================
print("\n  Validando o arquivo .tflite gerado...")

try:
    interpreter = tf.lite.Interpreter(model_path=MODELO_TFLITE)
    interpreter.allocate_tensors()

    input_details  = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"  Input  shape : {input_details[0]['shape']} | dtype: {input_details[0]['dtype'].__name__}")
    print(f"  Output shape : {output_details[0]['shape']} | dtype: {output_details[0]['dtype'].__name__}")

    # Cria imagem de teste com o dtype correto
    if input_details[0]['dtype'] == np.uint8:
        img_val = np.random.randint(0, 255, (1, TAMANHO_IMG, TAMANHO_IMG, 3), dtype=np.uint8)
    else:
        img_val = np.random.rand(1, TAMANHO_IMG, TAMANHO_IMG, 3).astype(np.float32)

    interpreter.set_tensor(input_details[0]['index'], img_val)
    interpreter.invoke()

    output    = interpreter.get_tensor(output_details[0]['index'])
    idx_pred  = int(np.argmax(output[0]))
    classe_pred = class_names[idx_pred] if idx_pred < len(class_names) else str(idx_pred)

    print(f"  Classe predita (imagem aleatória): {classe_pred}")
    print(f"  ✅ Validação TFLite concluída com sucesso!")

except Exception as e:
    print(f"  ⚠️  Erro na validação: {e}")
    print("  ℹ️  O arquivo foi gerado mas requer verificação manual no Flutter.")

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================
print(f"""
{"=" * 60}
CONVERSÃO CONCLUÍDA — RESUMO
{"=" * 60}

Modelo Keras original : {MODELO_ENTRADA}
Modelo TFLite gerado  : {MODELO_TFLITE} ({tamanho_mb:.2f} MB)
Modo de quantização   : {modo_conversao}
Labels                : {LABELS_SAIDA}
Classes               : {class_names}

Arquivos para copiar para o Flutter:
  → mobile/assets/models/{MODELO_TFLITE}
  → mobile/assets/{LABELS_SAIDA}

No classifier.dart, atualize:
  final String _modelPath  = 'assets/models/{MODELO_TFLITE}';
  final String _labelsPath = 'assets/{LABELS_SAIDA}';

No pubspec.yaml, confirme:
  assets:
    - assets/models/{MODELO_TFLITE}
    - assets/{LABELS_SAIDA}
{"=" * 60}
""")