import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras import mixed_precision
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from tensorflow.keras.regularizers import l2
import numpy as np
from sklearn.utils.class_weight import compute_class_weight
import os
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix

# --- CONFIGURAÇÃO DE HARDWARE ---
mixed_precision.set_global_policy('mixed_float16')

caminho_dataset = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset" 

TAMANHO_IMG = 224
BATCH_SIZE = 64 
EPOCHS_INICIAIS = 15 # Aumentado um pouco pois temos EarlyStopping
EPOCHS_FINETUNING = 15

print("========================================")
print(f"Versão do TensorFlow: {tf.__version__}")
gpu_devices = tf.config.list_physical_devices('GPU')
if len(gpu_devices) > 0:
    print(f"GPU Detectada: {tf.config.experimental.get_device_details(gpu_devices[0])['device_name']}")

# --- PREPARAÇÃO DAS IMAGENS (Augmentation Ajustado) ---
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=30,      # Reduzido levemente para evitar distorção extrema
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.15,
    zoom_range=0.2,
    brightness_range=[0.8, 1.2], # Ajuda com fotos tiradas em diferentes luzes no campo
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
    subset='validation',
    shuffle=False 
)

class_names = list(train_generator.class_indices.keys())

# --- CÁLCULO DE PESOS (Para equilibrar a Septoria) ---
classes_treino = train_generator.classes
pesos_calculados = compute_class_weight(
    class_weight='balanced',
    classes=np.unique(classes_treino),
    y=classes_treino
)
dicionario_pesos = dict(enumerate(pesos_calculados))

# --- ARQUITETURA DO MODELO ---
print("\n--- Construindo MobileNetV2 com Regularização L2 ---")
base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
base_model.trainable = False # Congela a base para o Warm-up

inputs = Input(shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
x = base_model(inputs, training=False)
x = GlobalAveragePooling2D()(x)
x = Dropout(0.5)(x) # Dropout alto contra Overfitting
# Adicionada Regularização L2 na camada de saída
outputs = Dense(len(class_names), 
                activation='softmax', 
                kernel_regularizer=l2(0.01), 
                dtype='float32')(x)

model = Model(inputs, outputs)

# --- CALLBACKS (Os seguranças do treino) ---
early_stop = EarlyStopping(monitor='val_loss', patience=4, restore_best_weights=True, verbose=1)
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=2, min_lr=1e-7, verbose=1)
checkpoint = ModelCheckpoint('melhor_modelo_soja.keras', monitor='val_accuracy', save_best_only=True, verbose=1)

# --- TREINAMENTO FASE 1 (Cabeça) ---
print("\n--- Fase 1: Treinando Camadas Superiores ---")
model.compile(optimizer=Adam(learning_rate=0.001), loss='categorical_crossentropy', metrics=['accuracy'])

history = model.fit(
    train_generator,
    epochs=EPOCHS_INICIAIS,
    validation_data=validation_generator,
    class_weight=dicionario_pesos,
    callbacks=[early_stop, reduce_lr, checkpoint]
)

# --- TREINAMENTO FASE 2 (Fine-Tuning) ---
print("\n--- Fase 2: Ajuste Fino (Unfreezing) ---")
base_model.trainable = True
# Congelar apenas as primeiras 100 camadas
for layer in base_model.layers[:100]:
    layer.trainable = False

model.compile(optimizer=Adam(learning_rate=1e-5), loss='categorical_crossentropy', metrics=['accuracy'])

history_fine = model.fit(
    train_generator,
    epochs=EPOCHS_FINETUNING,
    validation_data=validation_generator,
    class_weight=dicionario_pesos,
    callbacks=[early_stop, reduce_lr, checkpoint]
)

# --- SALVAMENTO FINAL ---
model.save('modelo_soja_final.keras')
with open("labels.txt", "w") as f:
    for classe in class_names:
        f.write(f"{classe}\n")

# --- GRÁFICOS E AVALIAÇÃO ---
print("\n--- Gerando Gráficos e Matriz de Confusão ---")
acc = history.history['accuracy'] + history_fine.history['accuracy']
val_acc = history.history['val_accuracy'] + history_fine.history['val_accuracy']
loss = history.history['loss'] + history_fine.history['loss']
val_loss = history.history['val_loss'] + history_fine.history['val_loss']

# Plot Acurácia/Perda
plt.figure(figsize=(12, 5))
plt.subplot(1, 2, 1); plt.plot(acc, label='Treino'); plt.plot(val_acc, label='Validação'); plt.title('Acurácia'); plt.legend()
plt.subplot(1, 2, 2); plt.plot(loss, label='Treino'); plt.plot(val_loss, label='Validação'); plt.title('Perda'); plt.legend()
plt.savefig('grafico_treinamento_v2.png')

# Matriz de Confusão
validation_generator.reset()
Y_pred = model.predict(validation_generator)
y_pred_classes = np.argmax(Y_pred, axis=1)
y_true_classes = validation_generator.classes
cm = confusion_matrix(y_true_classes, y_pred_classes)

plt.figure(figsize=(10, 8))
sns.heatmap(cm, annot=True, fmt='d', cmap='Greens', xticklabels=class_names, yticklabels=class_names)
plt.title('Matriz de Confusão Final')
plt.savefig('matriz_confusao_v2.png')

print("\n--- Relatório Final ---")
print(classification_report(y_true_classes, y_pred_classes, target_names=class_names))