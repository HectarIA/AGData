import tensorflow as tf

print("Carregando o modelo .keras...")
model = tf.keras.models.load_model('modelo_soja.keras')

print("Configurando o Conversor...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# 1. Ativa a otimização
converter.optimizations = [tf.lite.Optimize.DEFAULT]

converter.target_spec.supported_types = [tf.float16]

converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS, 
    tf.lite.OpsSet.SELECT_TF_OPS
]

print("Convertendo para TFLite... (Isso pode levar alguns segundos)")
tflite_model = converter.convert()

with open('modelo_soja.tflite', 'wb') as f:
    f.write(tflite_model)

print("✅ SUCESSO! O modelo 'modelo_soja.tflite' foi gerado e quantizado.")