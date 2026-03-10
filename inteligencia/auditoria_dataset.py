"""
auditoria_dataset.py — rode no WSL antes do treino
Identifica por que imagens estão sendo excluídas pelo Keras/ImageDataGenerator
"""
import os
from pathlib import Path
from collections import Counter

dataset_path = Path("/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset")

# Extensões que o Keras/ImageDataGenerator aceita por padrão
EXTENSOES_KERAS = {'.jpg', '.jpeg', '.png', '.bmp', '.gif', '.ppm', '.tiff'}

print("=" * 60)
print("AUDITORIA DO DATASET")
print("=" * 60)

if not dataset_path.exists():
    print(f"❌ Path não encontrado: {dataset_path}")
    exit(1)

total_aceito = 0
total_rejeitado = 0

for classe_dir in sorted(dataset_path.iterdir()):
    if not classe_dir.is_dir():
        continue

    arquivos      = [f for f in classe_dir.iterdir() if f.is_file()]
    aceitos       = [f for f in arquivos if f.suffix.lower() in EXTENSOES_KERAS]
    rejeitados    = [f for f in arquivos if f.suffix.lower() not in EXTENSOES_KERAS]
    zerados       = [f for f in aceitos  if f.stat().st_size == 0]
    subpastas     = [d for d in classe_dir.iterdir() if d.is_dir()]
    ext_counter   = Counter(f.suffix.lower() for f in arquivos)

    status = "✅" if not rejeitados and not zerados and not subpastas else "⚠️ "
    print(f"\n{status} {classe_dir.name}")
    print(f"   Aceitos pelo Keras : {len(aceitos)}")
    print(f"   Extensões          : {dict(sorted(ext_counter.items()))}")

    if rejeitados:
        print(f"   🔴 REJEITADOS ({len(rejeitados)}): extensões não suportadas")
        rej_ext = Counter(f.suffix.lower() for f in rejeitados)
        print(f"      Extensões rejeitadas: {dict(rej_ext)}")
        print(f"      Exemplos: {[f.name for f in rejeitados[:3]]}")

    if zerados:
        print(f"   🔴 ARQUIVOS CORROMPIDOS/ZERADOS: {len(zerados)}")
        print(f"      Exemplos: {[f.name for f in zerados[:3]]}")

    if subpastas:
        print(f"   ⚠️  SUBPASTAS ENCONTRADAS: {[d.name for d in subpastas]}")
        print(f"      Keras ignora imagens dentro de subpastas!")
        # Conta imagens escondidas nas subpastas
        imgs_subpastas = sum(
            len([f for f in sub.iterdir() if f.suffix.lower() in EXTENSOES_KERAS])
            for sub in subpastas
        )
        if imgs_subpastas:
            print(f"      🔴 {imgs_subpastas} imagens escondidas nas subpastas!")

    total_aceito    += len(aceitos)
    total_rejeitado += len(rejeitados)

print(f"\n{'=' * 60}")
print(f"RESUMO")
print(f"{'=' * 60}")
print(f"Total aceito pelo Keras  : {total_aceito}")
print(f"Total ignorado/rejeitado : {total_rejeitado}")

# Treino = 80% do total aceito
treino_estimado = int(total_aceito * 0.8)
val_estimado    = total_aceito - treino_estimado
print(f"\nApós split 80/20:")
print(f"  Treino estimado     : {treino_estimado}")
print(f"  Validação estimada  : {val_estimado}")

print(f"\n{'=' * 60}")
print(f"Extensões aceitas pelo Keras: {sorted(EXTENSOES_KERAS)}")
print(f"{'=' * 60}")