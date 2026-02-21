import tensorflow as tf

print("Carregando o modelo original...")
tf.keras.mixed_precision.set_global_policy('float32')
model = tf.keras.models.load_model('modelo_soja_2.keras')

print("Limpando os rastros da RTX 3060 (Forçando float32 puro)...")
config = model.get_config()

def limpar_dic(d):
    if isinstance(d, dict):
        for k, v in d.items():
            if k == 'dtype':
                if isinstance(v, dict) and v.get('class_name') == 'Policy':
                    d[k] = 'float32'
                elif v == 'mixed_float16':
                    d[k] = 'float32'
            else:
                limpar_dic(v)
    elif isinstance(d, list):
        for item in d:
            limpar_dic(item)

limpar_dic(config)

if model.__class__.__name__ == 'Sequential':
    modelo_limpo = tf.keras.Sequential.from_config(config)
else:
    modelo_limpo = tf.keras.Model.from_config(config)

modelo_limpo.set_weights(model.get_weights())

print("Convertendo para TFLite limpo...")
converter = tf.lite.TFLiteConverter.from_keras_model(modelo_limpo)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

with open('modelo_soja_2.tflite', 'wb') as f:
    f.write(converter.convert())

print("✅ SUCESSO! O modelo 'modelo_soja_2.tflite' foi limpo e recriado.")