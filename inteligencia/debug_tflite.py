import tensorflow as tf
import numpy as np
from tensorflow.keras.utils import load_img, img_to_array


CAMINHO_MODELO = "modelo_soja_2.tflite" 
CAMINHO_IMAGEM = "teste_google_oidio.jpg" 

interpreter = tf.lite.Interpreter(model_path=CAMINHO_MODELO)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\n--- SETUP DO MODELO ---")
print(f"Formato esperado: {input_details[0]['shape']}")
print(f"Tipo de dados: {input_details[0]['dtype']}")

img = load_img(CAMINHO_IMAGEM, target_size=(224, 224))
img_array = img_to_array(img)

img_array = img_array / 255.0 

input_data = np.expand_dims(img_array, axis=0).astype(np.float32)

interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])

classes = ['Ferrugem', 'Mancha Alvo', 'Oídio', 'Saudável']

print("\n--- RESULTADO DO TFLITE NO PC ---")
print(f"Array Bruto: {output_data[0]}") 

index_vencedor = np.argmax(output_data[0]) 
doenca = classes[index_vencedor]
confianca = output_data[0][index_vencedor] * 100

print(f"Veredito: {doenca.upper()}")
print(f"Confiança: {confianca:.2f}%")

print("\n--- DETALHAMENTO ---")
for i, nome in enumerate(classes):
    print(f"{nome}: {output_data[0][i]*100:.2f}%")