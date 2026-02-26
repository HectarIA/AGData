import tensorflow as tf
import numpy as np
import os
from tensorflow.keras.utils import load_img, img_to_array

print("Carregando o cérebro da IA...")
model = tf.keras.models.load_model('modelo_soja_2.keras')

try:
    with open("labels.txt", "r") as f:
        class_names = [linha.strip() for linha in f.readlines()]
    print(f"Classes carregadas com sucesso: {class_names}")
except FileNotFoundError:
    print("⚠️ Arquivo 'labels.txt' não encontrado. Usando classes manuais (verifique a ordem das suas pastas!).")
    class_names = ['ferrugem', 'mancha_alvo', 'mancha_parda', 'oidio', 'saudavel']

def testar_imagem(caminho_imagem):
    if not os.path.exists(caminho_imagem):
        print(f"❌ Erro: Imagem '{caminho_imagem}' não encontrada.")
        return

    img = load_img(caminho_imagem, target_size=(224, 224))
    img_array = img_to_array(img)
    
    img_array = img_array / 255.0 
    
    img_array = tf.expand_dims(img_array, 0) 

    print("\nAnalisando a folha... 🔬")
    predictions = model.predict(img_array)
    
    score = predictions[0]
    classe_vencedora = class_names[np.argmax(score)]
    certeza = 100 * np.max(score)

    print("-" * 40)
    print(f"📷 Resultado para: {caminho_imagem}")
    print(f"🌱 Diagnóstico principal: **{classe_vencedora}**")
    print(f"🎯 Grau de certeza: {certeza:.2f}%\n")

    print("Detalhes completos da análise:")
    for i in range(len(class_names)):
        print(f"  - {class_names[i]}: {100 * score[i]:.2f}%")
    print("-" * 40)


testar_imagem('teste.jpg')