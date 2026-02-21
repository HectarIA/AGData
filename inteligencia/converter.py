import tensorflow as tf

print("Carregando o modelo original...")
# 1. Avisa o TensorFlow para parar de usar mixed precision
tf.keras.mixed_precision.set_global_policy('float32')
model = tf.keras.models.load_model('modelo_soja.keras')

print("Limpando os rastros da RTX 3060 (Forçando float32 puro)...")
# 2. Extrai o "esqueleto" do modelo (configurações)
config = model.get_config()

# 3. Função caçadora: Procura qualquer rastro de 'mixed_float16' e substitui por 'float32'
def limpar_dic(d):
    if isinstance(d, dict):
        for k, v in d.items():
            if k == 'dtype':
                # Remove os rastros da política de precisão mista
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

# 4. Reconstrói o modelo com o esqueleto 100% limpo
if model.__class__.__name__ == 'Sequential':
    modelo_limpo = tf.keras.Sequential.from_config(config)
else:
    modelo_limpo = tf.keras.Model.from_config(config)

# 5. Injeta o "cérebro" (pesos que já treinamos) de volta no esqueleto limpo
modelo_limpo.set_weights(model.get_weights())

print("Convertendo para TFLite limpo...")
# Agora não precisamos mais daquele "supported_types" que estava causando problemas
converter = tf.lite.TFLiteConverter.from_keras_model(modelo_limpo)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

with open('modelo_soja.tflite', 'wb') as f:
    f.write(converter.convert())

print("✅ SUCESSO! O modelo 'modelo_soja.tflite' foi limpo e recriado.")