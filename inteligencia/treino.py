import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras import mixed_precision # <--- NOVIDADE 1
import os

mixed_precision.set_global_policy('mixed_float16')

# --- CONFIGURAÇÕES ---
# ATENÇÃO: No WSL, o C:\ vira /mnt/c/
caminho_dataset = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset" 

TAMANHO_IMG = 224
BATCH_SIZE = 64 # Aumentei para 64 pois sua 3060 aguenta e acelera o treino
EPOCHS_INICIAIS = 10 
EPOCHS_FINETUNING = 10 

print("========================================")
print(f"Versão do TensorFlow: {tf.__version__}")
gpu_devices = tf.config.list_physical_devices('GPU')
print(f"GPU Disponível: {len(gpu_devices) > 0}")
if len(gpu_devices) > 0:
    print(f"Nome da GPU: {tf.config.experimental.get_device_details(gpu_devices[0])['device_name']}")

# --- PREPARAÇÃO DAS IMAGENS ---
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=40,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest',
    validation_split=0.2
)

print("\n--- Carregando Dataset ---")
train_generator = train_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    shuffle=True
)

validation_generator = train_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation'
)

class_names = list(train_generator.class_indices.keys())
print(f"Classes detectadas: {class_names}")

# --- FASE 1: TRANSFER LEARNING ---
print("\n--- Construindo MobileNetV2 ---")
base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
base_model.trainable = False

inputs = Input(shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
x = base_model(inputs, training=False)
x = GlobalAveragePooling2D()(x)
x = Dropout(0.2)(x)
# Importante: A camada de saída deve ser float32 para estabilidade numérica
outputs = Dense(len(class_names), activation='softmax', dtype='float32')(x)

model = Model(inputs, outputs)

model.compile(optimizer=Adam(learning_rate=0.001),
              loss='categorical_crossentropy',
              metrics=['accuracy'])

print("\n--- Fase 1: Treinando Cabeça ---")
history = model.fit(
    train_generator,
    epochs=EPOCHS_INICIAIS,
    validation_data=validation_generator
)

# --- FASE 2: FINE TUNING ---
print("\n--- Fase 2: Ajuste Fino ---")
base_model.trainable = True

# Vamos treinar as últimas 50 camadas (MobileNet tem 155)
# Descongelar demais pode estragar os pesos se o dataset for pequeno
fine_tune_at = 100
for layer in base_model.layers[:fine_tune_at]:
    layer.trainable = False

model.compile(optimizer=Adam(learning_rate=1e-5), # Taxa bem baixa
              loss='categorical_crossentropy',
              metrics=['accuracy'])

history_fine = model.fit(
    train_generator,
    epochs=EPOCHS_FINETUNING,
    validation_data=validation_generator
)

# --- SALVAMENTO ---
caminho_modelo = 'modelo_soja.keras'
model.save(caminho_modelo)
print(f"\n✅ SUCESSO! Modelo salvo em: {caminho_modelo}")

# Exportar labels
with open("labels.txt", "w") as f:
    for classe in class_names:
        f.write(f"{classe}\n")