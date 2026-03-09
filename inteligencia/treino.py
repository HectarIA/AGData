import tensorflow as tf
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input
from tensorflow.keras.layers import (
    Dense, GlobalAveragePooling2D, GlobalMaxPooling2D,
    Dropout, Input, Lambda, Concatenate, BatchNormalization
)
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import numpy as np
from sklearn.utils.class_weight import compute_class_weight
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix

# =============================================================================
# CONFIGURAÇÕES GERAIS
# =============================================================================
caminho_dataset   = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset_balanceado"
TAMANHO_IMG       = 256
BATCH_SIZE        = 64
EPOCHS_INICIAIS   = 25
EPOCHS_FINETUNING = 30

# Probabilidades de aplicar cada técnica de augmentation avançado por batch
# Valores calibrados para dataset pequeno e classes desbalanceadas
PROB_CUTMIX  = 0.4   # Aplicado em 40% dos batches
PROB_MIXUP   = 0.3   # Aplicado em 30% dos batches (quando CutMix não é aplicado)
ALPHA_CUTMIX = 1.0   # Parâmetro Beta distribution para tamanho do corte
ALPHA_MIXUP  = 0.2   # Parâmetro Beta distribution para força da mistura
               # 0.2 = mistura suave (80/20) — agressivo demais confunde o treino

print("========================================")
print(f"Versão do TensorFlow: {tf.__version__}")
gpu_devices = tf.config.list_physical_devices('GPU')
if gpu_devices:
    print(f"GPU Detectada: {tf.config.experimental.get_device_details(gpu_devices[0])['device_name']}")
else:
    print("Nenhuma GPU detectada — rodando em CPU.")
print("========================================\n")

# =============================================================================
# DATA AUGMENTATION BASE
# Augmentation especializado para doenças foliares:
# - channel_shift_range: simula variações de clorofila/stress hídrico na folha
#   (folhas amareladas, avermelhadas por deficiência nutricional ou seca)
# - vertical_flip: folhas podem ser fotografadas de qualquer orientação no campo
# - brightness_range ampliado [0.7, 1.3]: simula sombra de copa de árvore
#   vs luz direta do sol do meio-dia (condição real do agricultor no campo)
# SEM rescale — preprocess_input cuida da normalização dentro do modelo
# =============================================================================
train_datagen = ImageDataGenerator(
    rotation_range=30,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.15,
    zoom_range=0.25,              # Aumentado: simula distância variável da câmera
    brightness_range=[0.7, 1.3],  # Ampliado: cobre mais condições de luz de campo
    horizontal_flip=True,
    vertical_flip=True,           # NOVO: folha pode estar em qualquer orientação
    channel_shift_range=20.0,     # NOVO: simula variações de cor/stress da planta
    fill_mode='nearest',
    validation_split=0.2
)

val_datagen = ImageDataGenerator(
    validation_split=0.2
)

# =============================================================================
# CARREGAMENTO DO DATASET
# =============================================================================
print("--- Carregando Dataset ---")

train_generator = train_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    shuffle=True
)

validation_generator = val_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation',
    shuffle=False
)

class_names = list(train_generator.class_indices.keys())
num_classes = len(class_names)
print(f"\nClasses detectadas ({num_classes}): {class_names}")

# =============================================================================
# PESOS DE CLASSE
# =============================================================================
classes_treino   = train_generator.classes
pesos_calculados = compute_class_weight(
    class_weight='balanced',
    classes=np.unique(classes_treino),
    y=classes_treino
)
dicionario_pesos = dict(enumerate(pesos_calculados))
print(f"\nPesos das classes calculados:")
for idx, (classe, peso) in enumerate(zip(class_names, pesos_calculados)):
    print(f"  [{idx}] {classe}: {peso:.4f}")

# =============================================================================
# TÉCNICA #1 — CUTMIX
#
# O que faz: recorta uma região retangular aleatória da imagem B e cola
# sobre a imagem A. Os labels são misturados proporcionalmente à área colada.
# Exemplo: se o corte ocupa 30% da área, o label final é 70% classe_A + 30% classe_B.
#
# Por que é crucial para septoria/mancha_alvo:
# Essas duas classes têm manchas com aparência similar mas padrões de
# distribuição diferentes na folha. Ao misturar regiões das duas durante
# o treino, forçamos o modelo a aprender features locais discriminativas
# (o halo da mancha_alvo, os pontos puntiformes da septoria) em vez de
# decorar o padrão global da imagem inteira.
#
# O lambda é amostrado de uma distribuição Beta(alpha, alpha):
# - Alpha=1.0 → cortes entre 0% e 100% da área (uniforme)
# - Valores próximos de 0 = corte pequeno, próximos de 1 = corte grande
# =============================================================================
def cutmix_batch(images, labels, alpha=ALPHA_CUTMIX):
    batch_size = tf.shape(images)[0]
    lam        = np.random.beta(alpha, alpha)

    # Dimensões do corte baseadas em lambda
    # cut_ratio é a fração do lado da imagem que será cortada
    cut_ratio = np.sqrt(1.0 - lam)
    cut_h     = int(TAMANHO_IMG * cut_ratio)
    cut_w     = int(TAMANHO_IMG * cut_ratio)

    # Posição aleatória do corte (centro)
    cx = np.random.randint(cut_w // 2, TAMANHO_IMG - cut_w // 2 + 1)
    cy = np.random.randint(cut_h // 2, TAMANHO_IMG - cut_h // 2 + 1)

    # Coordenadas do retângulo de corte (clampadas aos limites da imagem)
    x1 = np.clip(cx - cut_w // 2, 0, TAMANHO_IMG)
    x2 = np.clip(cx + cut_w // 2, 0, TAMANHO_IMG)
    y1 = np.clip(cy - cut_h // 2, 0, TAMANHO_IMG)
    y2 = np.clip(cy + cut_h // 2, 0, TAMANHO_IMG)

    # Lambda real (área do corte pode diferir do lambda amostrado por clamp)
    lam_real = 1.0 - ((x2 - x1) * (y2 - y1)) / (TAMANHO_IMG * TAMANHO_IMG)

    # Embaralha o batch para criar os pares de mistura
    indices = np.random.permutation(images.shape[0])
    images_b = images[indices]
    labels_b = labels[indices]

    # Cria cópia e substitui a região com o patch da imagem B
    images_mixed = images.copy()
    images_mixed[:, y1:y2, x1:x2, :] = images_b[:, y1:y2, x1:x2, :]

    # Label misto proporcional à área real
    labels_mixed = lam_real * labels + (1.0 - lam_real) * labels_b

    return images_mixed, labels_mixed


# =============================================================================
# TÉCNICA #2 — MIXUP
#
# O que faz: interpola linearmente os pixels de duas imagens e seus labels.
# image_mixed = lambda * imagem_A + (1 - lambda) * imagem_B
# label_mixed = lambda * label_A  + (1 - lambda) * label_B
#
# Por que é crucial para o nosso problema:
# Com apenas 108 amostras de septoria, o modelo aprende uma fronteira de
# decisão "rígida" que não generaliza. O MixUp cria exemplos "intermediários"
# entre classes, forçando o modelo a aprender uma fronteira suave e
# contínua. Quando vê uma septoria ambígua no campo, em vez de forçar
# uma resposta errada com alta confiança, o modelo distribui probabilidade
# entre as classes similares — comportamento muito mais seguro para uso real.
#
# Alpha=0.2 foi escolhido deliberadamente baixo:
# - Alpha alto (ex: 0.5) cria misturas 50/50 que são imagens "impossíveis"
#   que nunca existiriam no campo, prejudicando a aprendizagem
# - Alpha=0.2 cria misturas suaves (ex: 80/20) que ainda parecem com a
#   classe dominante mas com "toque" da classe secundária
# =============================================================================
def mixup_batch(images, labels, alpha=ALPHA_MIXUP):
    lam     = np.random.beta(alpha, alpha)
    indices = np.random.permutation(images.shape[0])

    images_mixed = lam * images + (1.0 - lam) * images[indices]
    labels_mixed = lam * labels + (1.0 - lam) * labels[indices]

    return images_mixed, labels_mixed


# =============================================================================
# GENERATOR CUSTOMIZADO — aplica CutMix e MixUp sobre o generator base
#
# Lógica de decisão por batch:
# - 40% dos batches: aplica CutMix
# - 30% dos batches restantes (~18% do total): aplica MixUp
# - Demais batches: passa sem modificação (augmentation base já aplicado)
#
# Por que não aplicar sempre:
# Aplicar CutMix/MixUp em 100% dos batches impede que o modelo veja
# exemplos "limpos" de cada classe, dificultando o aprendizado das
# features puras — especialmente problemático para septoria que já tem
# poucos exemplos. A combinação 40%/30%/30% balanceia diversidade e clareza.
# =============================================================================
def generator_com_augmentation_avancado(base_generator):
    for images, labels in base_generator:
        r = np.random.random()

        if r < PROB_CUTMIX:
            images, labels = cutmix_batch(images, labels)
        elif r < PROB_CUTMIX + PROB_MIXUP:
            images, labels = mixup_batch(images, labels)
        # else: batch original sem modificação adicional

        yield images, labels


# =============================================================================
# FOCAL LOSS — mantida da v5, essencial para classes minoritárias
# =============================================================================
class FocalLoss(tf.keras.losses.Loss):
    def __init__(self, gamma=2.0, label_smoothing=0.1, **kwargs):
        super().__init__(**kwargs)
        self.gamma           = gamma
        self.label_smoothing = label_smoothing

    def call(self, y_true, y_pred):
        num_cls = tf.cast(tf.shape(y_true)[-1], tf.float32)
        y_true  = y_true * (1.0 - self.label_smoothing) + (self.label_smoothing / num_cls)
        y_pred  = tf.clip_by_value(y_pred, 1e-7, 1.0)
        ce      = -y_true * tf.math.log(y_pred)
        weight  = tf.pow(1.0 - y_pred, self.gamma)
        return tf.reduce_mean(tf.reduce_sum(weight * ce, axis=-1))

    def get_config(self):
        config = super().get_config()
        config.update({'gamma': self.gamma, 'label_smoothing': self.label_smoothing})
        return config

loss_fn = FocalLoss(gamma=2.0, label_smoothing=0.1, name='focal_loss')

# =============================================================================
# ARQUITETURA — Dual Pooling + Cabeça Profunda (mantida da v5)
# Arquitetura validada como correta — o problema é o dataset, não o modelo
# =============================================================================
print("\n--- Construindo MobileNetV3 Large com Dual Pooling + Cabeça Profunda ---")

base_model = MobileNetV3Large(
    weights='imagenet',
    include_top=False,
    input_shape=(TAMANHO_IMG, TAMANHO_IMG, 3)
)
base_model.trainable = False

inputs = Input(shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
x_pre  = Lambda(lambda img: preprocess_input(img), name='mobilenetv3_preprocessing')(inputs)

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

model = Model(inputs, outputs)
model.summary()

# =============================================================================
# STEPS_PER_EPOCH customizado
# Com o generator customizado (Python generator), o Keras não consegue
# calcular automaticamente steps_per_epoch. Precisamos informar manualmente.
# steps = ceil(num_amostras_treino / batch_size)
# =============================================================================
steps_por_epoca     = len(train_generator)
steps_por_epoca_val = len(validation_generator)

# =============================================================================
# CALLBACK CUSTOMIZADO — Monitor de Overfitting
# =============================================================================
class OverfittingMonitor(tf.keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        acc     = logs.get('accuracy', 0)
        val_acc = logs.get('val_accuracy', 0)
        ratio   = val_acc / acc if acc > 0 else 0
        status  = "✅ OK" if ratio > 0.85 else ("⚠️  ALERTA" if ratio > 0.70 else "🔴 OVERFITTING")
        print(f"  → [Monitor] val/train ratio: {ratio:.2f} {status} | val_acc: {val_acc:.4f}")

# =============================================================================
# CALLBACKS
# =============================================================================
early_stop = EarlyStopping(
    monitor='val_loss', patience=8, restore_best_weights=True, verbose=1
)
reduce_lr = ReduceLROnPlateau(
    monitor='val_loss', factor=0.3, patience=4, min_lr=1e-8, verbose=1
)
checkpoint = ModelCheckpoint(
    'melhor_modelo_soja.keras', monitor='val_accuracy', save_best_only=True, verbose=1
)
callbacks_lista = [early_stop, reduce_lr, checkpoint, OverfittingMonitor()]

# =============================================================================
# FASE 1 — WARM-UP com CutMix + MixUp ativos
# =============================================================================
print("\n--- Fase 1: Treinando Cabeça Profunda (Warm-up) ---")
print(f"    LR: 5e-5 | Batch: {BATCH_SIZE} | CutMix: {PROB_CUTMIX*100:.0f}% | MixUp: {PROB_MIXUP*100:.0f}%\n")

model.compile(
    optimizer=Adam(learning_rate=5e-5),
    loss=loss_fn,
    metrics=['accuracy']
)

train_gen_augmentado = generator_com_augmentation_avancado(train_generator)

history = model.fit(
    train_gen_augmentado,
    steps_per_epoch=steps_por_epoca,
    epochs=EPOCHS_INICIAIS,
    validation_data=validation_generator,
    validation_steps=steps_por_epoca_val,
    class_weight=dicionario_pesos,
    callbacks=callbacks_lista
)

# =============================================================================
# FASE 2 — FINE-TUNING com 50 camadas + CutMix + MixUp
# Reinicia o generator para garantir que o shuffle acontece novamente
# =============================================================================
print("\n--- Fase 2: Ajuste Fino (Fine-Tuning — 50 camadas) ---")

base_model.trainable = True

num_camadas_base      = len(base_model.layers)
camadas_para_congelar = num_camadas_base - 50
print(f"Total de camadas na base: {num_camadas_base}")
print(f"Camadas congeladas: {camadas_para_congelar} | Camadas descongeladas: 50")

for layer in base_model.layers[:camadas_para_congelar]:
    layer.trainable = False

# BN sempre em modo inferência — estatísticas do ImageNet não devem ser corrompidas
for layer in base_model.layers:
    if isinstance(layer, tf.keras.layers.BatchNormalization):
        layer.trainable = False

treinaveis = sum(1 for l in base_model.layers if l.trainable)
print(f"Camadas efetivamente treináveis (excl. BN): {treinaveis}")
print(f"    LR: 5e-6 | Batch: {BATCH_SIZE} | CutMix: {PROB_CUTMIX*100:.0f}% | MixUp: {PROB_MIXUP*100:.0f}%\n")

model.compile(
    optimizer=Adam(learning_rate=5e-6),
    loss=loss_fn,
    metrics=['accuracy']
)

# Reinicia o generator base e cria novo generator augmentado para fase 2
train_generator.reset()
train_gen_augmentado_ft = generator_com_augmentation_avancado(train_generator)

history_fine = model.fit(
    train_gen_augmentado_ft,
    steps_per_epoch=steps_por_epoca,
    epochs=EPOCHS_FINETUNING,
    validation_data=validation_generator,
    validation_steps=steps_por_epoca_val,
    class_weight=dicionario_pesos,
    callbacks=callbacks_lista
)

# =============================================================================
# SALVAMENTO FINAL
# =============================================================================
model.save('modelo_soja_final.keras')
print("\n✅ Modelo salvo em: modelo_soja_final.keras")

with open("labels.txt", "w") as f:
    for classe in class_names:
        f.write(f"{classe}\n")
print("✅ Labels salvas em: labels.txt")

# =============================================================================
# GRÁFICOS
# =============================================================================
print("\n--- Gerando Gráficos de Treinamento ---")

acc        = history.history['accuracy']     + history_fine.history['accuracy']
val_acc    = history.history['val_accuracy'] + history_fine.history['val_accuracy']
loss_h     = history.history['loss']         + history_fine.history['loss']
val_loss_h = history.history['val_loss']     + history_fine.history['val_loss']

fase1_epocas = len(history.history['accuracy'])

plt.figure(figsize=(14, 5))

plt.subplot(1, 2, 1)
plt.plot(acc, label='Treino', color='steelblue')
plt.plot(val_acc, label='Validação', color='darkorange')
plt.axvline(x=fase1_epocas - 1, color='gray', linestyle='--', label='Início Fine-Tuning')
plt.title('Acurácia por Época — v6 (CutMix + MixUp)')
plt.xlabel('Época'); plt.ylabel('Acurácia'); plt.legend()

plt.subplot(1, 2, 2)
plt.plot(loss_h, label='Treino', color='steelblue')
plt.plot(val_loss_h, label='Validação', color='darkorange')
plt.axvline(x=fase1_epocas - 1, color='gray', linestyle='--', label='Início Fine-Tuning')
plt.title('Perda por Época — v6 (Focal Loss)')
plt.xlabel('Época'); plt.ylabel('Focal Loss'); plt.legend()

plt.tight_layout()
plt.savefig('grafico_treinamento_v6.png', dpi=150)
plt.close()
print("✅ Gráfico salvo em: grafico_treinamento_v6.png")

# =============================================================================
# MATRIZ DE CONFUSÃO FINAL
# =============================================================================
print("\n--- Gerando Matriz de Confusão ---")

validation_generator.reset()
Y_pred         = model.predict(validation_generator, verbose=1)
y_pred_classes = np.argmax(Y_pred, axis=1)
y_true_classes = validation_generator.classes

cm      = confusion_matrix(y_true_classes, y_pred_classes)
cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]

fig, axes = plt.subplots(1, 2, figsize=(20, 8))

sns.heatmap(cm, annot=True, fmt='d', cmap='Greens',
            xticklabels=class_names, yticklabels=class_names, ax=axes[0])
axes[0].set_title('Matriz de Confusão — Contagem Absoluta')
axes[0].set_ylabel('Real'); axes[0].set_xlabel('Predito')

sns.heatmap(cm_norm, annot=True, fmt='.0%', cmap='Greens',
            xticklabels=class_names, yticklabels=class_names, ax=axes[1])
axes[1].set_title('Matriz de Confusão — Percentual por Classe')
axes[1].set_ylabel('Real'); axes[1].set_xlabel('Predito')

plt.tight_layout()
plt.savefig('matriz_confusao_v6.png', dpi=150)
plt.close()
print("✅ Matriz de confusão salva em: matriz_confusao_v6.png")

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================
print("\n========================================")
print("RELATÓRIO DE CLASSIFICAÇÃO FINAL — v6")
print("========================================")
report = classification_report(
    y_true_classes, y_pred_classes,
    target_names=class_names,
    output_dict=True
)
print(classification_report(y_true_classes, y_pred_classes, target_names=class_names))

print("\n--- Diagnóstico por Classe (meta: F1 ≥ 0.90) ---")
for classe in class_names:
    f1     = report[classe]['f1-score']
    status = "✅" if f1 >= 0.90 else ("⚠️ " if f1 >= 0.75 else "🔴")
    print(f"  {status} {classe:<15} F1: {f1:.2f}")