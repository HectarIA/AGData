import tensorflow as tf
import numpy as np
import os
from tensorflow.keras.utils import load_img, img_to_array

print("Carregando o cérebro da IA...")
model = tf.keras.models.load_model('modelo_soja_2.keras')

classes = ['Ferrugem', 'Mancha Alvo', 'Oídio', 'Saudável']

def testar_imagem(caminho_imagem):
    if not os.path.exists(caminho_imagem):
        print(f"Erro: Imagem '{caminho_imagem}' não encontrada.")
        return

    img = load_img(caminho_imagem, target_size=(224, 224))
    img_array = img_to_array(img)
    img_array = tf.expand_dims(img_array, 0) # Cria um "lote" de 1 imagem para a IA ler

    # Faz a previsão
    predictions = model.predict(img_array)
    
    # Como o modelo já cospe a probabilidade final (softmax), pegamos direto o resultado
    score = predictions[0]
    classe_vencedora = class_names[np.argmax(score)]
    certeza = 100 * np.max(score)

    print("-" * 30)
    print(f"📷 Resultado para: {caminho_imagem}")
    print(f"🌱 Diagnóstico: **{classe_vencedora}**")
    print(f"🎯 Certeza: {certeza:.2f}%\n")

    # Mostra o raio-x das outras opções para você ver como a IA pensou
    print("Detalhes da análise:")
    for i in range(len(class_names)):
        print(f"  - {class_names[i]}: {100 * score[i]:.2f}%")
    print("-" * 30)

# Chame a função passando o nome da foto que você quer testar
testar_imagem('teste.jpg')