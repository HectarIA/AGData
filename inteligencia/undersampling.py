import os
import shutil
import random
from pathlib import Path
from collections import defaultdict

# =============================================================================
# CONFIGURAÇÕES — ajuste apenas estas variáveis
# =============================================================================

# Pasta raiz do seu dataset original (NUNCA será modificada)
DATASET_ORIGINAL = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset"

# Pasta de destino do dataset balanceado (será criada do zero)
DATASET_BALANCEADO = "/mnt/c/Users/User/Desktop/AGdata/inteligencia/dataset_balanceado"

# Número máximo de imagens por classe
# Definido como 650 — ligeiramente acima de septoria (~550) para dar
# uma margem de diversidade nas classes maiores sem desequilibrar
LIMITE_POR_CLASSE = 650

# Semente aleatória — garante que rodar o script duas vezes
# produz exatamente o mesmo resultado (reprodutibilidade)
SEMENTE = 42

# Extensões de imagem aceitas
EXTENSOES_VALIDAS = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}

# =============================================================================
# SCRIPT
# =============================================================================

def listar_imagens(pasta_classe: Path) -> list:
    """Retorna lista de todos os arquivos de imagem em uma pasta."""
    imagens = []
    for arquivo in pasta_classe.iterdir():
        if arquivo.suffix.lower() in EXTENSOES_VALIDAS:
            imagens.append(arquivo)
    return imagens


def undersampling_estratificado():
    random.seed(SEMENTE)

    dataset_original  = Path(DATASET_ORIGINAL)
    dataset_balanceado = Path(DATASET_BALANCEADO)

    # Verifica se o dataset original existe
    if not dataset_original.exists():
        print(f"❌ Dataset original não encontrado: {DATASET_ORIGINAL}")
        return

    # Se a pasta de destino já existe, remove e recria do zero
    # Garante que reruns não acumulam arquivos antigos
    if dataset_balanceado.exists():
        print(f"⚠️  Pasta '{DATASET_BALANCEADO}' já existe — removendo para recriar...")
        shutil.rmtree(dataset_balanceado)

    dataset_balanceado.mkdir(parents=True, exist_ok=True)

    # Identifica as classes (subpastas do dataset original)
    classes = sorted([
        d for d in dataset_original.iterdir()
        if d.is_dir() and not d.name.startswith('.')
    ])

    if not classes:
        print("❌ Nenhuma subpasta (classe) encontrada no dataset original.")
        return

    print("=" * 60)
    print("UNDERSAMPLING ESTRATIFICADO — AGdata")
    print("=" * 60)
    print(f"\nDataset original : {DATASET_ORIGINAL}")
    print(f"Dataset destino  : {DATASET_BALANCEADO}")
    print(f"Limite por classe: {LIMITE_POR_CLASSE} imagens")
    print(f"Semente aleatória: {SEMENTE}")
    print(f"\nClasses encontradas: {len(classes)}")

    # ==========================================================================
    # INVENTÁRIO — conta imagens antes de qualquer operação
    # ==========================================================================
    print("\n--- Inventário do Dataset Original ---")
    inventario = {}
    for classe_dir in classes:
        imagens = listar_imagens(classe_dir)
        inventario[classe_dir.name] = imagens
        status = "✅" if len(imagens) <= LIMITE_POR_CLASSE else "✂️  será reduzida"
        print(f"  {classe_dir.name:<20} {len(imagens):>5} imagens  {status}")

    total_original = sum(len(v) for v in inventario.values())
    print(f"\n  Total original: {total_original} imagens")

    # ==========================================================================
    # SELEÇÃO E CÓPIA
    # ==========================================================================
    print("\n--- Criando Dataset Balanceado ---")
    resumo = defaultdict(dict)

    for classe_nome, imagens in inventario.items():
        pasta_destino = dataset_balanceado / classe_nome
        pasta_destino.mkdir(parents=True, exist_ok=True)

        # Se a classe tem mais imagens que o limite, seleciona aleatoriamente
        # Se tem menos ou igual, copia todas (não descarta nada)
        if len(imagens) > LIMITE_POR_CLASSE:
            selecionadas = random.sample(imagens, LIMITE_POR_CLASSE)
        else:
            selecionadas = imagens
            if len(imagens) < LIMITE_POR_CLASSE:
                print(f"  ⚠️  {classe_nome}: apenas {len(imagens)} imagens "
                      f"(abaixo do limite de {LIMITE_POR_CLASSE}) — copiando todas")

        # Copia os arquivos selecionados para o dataset balanceado
        for imagem_src in selecionadas:
            destino = pasta_destino / imagem_src.name
            # Resolve conflito de nomes duplicados adicionando índice
            if destino.exists():
                stem   = imagem_src.stem
                suffix = imagem_src.suffix
                contador = 1
                while destino.exists():
                    destino = pasta_destino / f"{stem}_{contador}{suffix}"
                    contador += 1
            shutil.copy2(imagem_src, destino)

        resumo[classe_nome] = {
            'original'   : len(imagens),
            'selecionadas': len(selecionadas),
            'removidas'  : len(imagens) - len(selecionadas)
        }

        barra = "█" * int(len(selecionadas) / LIMITE_POR_CLASSE * 20)
        print(f"  ✅ {classe_nome:<20} {len(selecionadas):>5} imagens copiadas  "
              f"[{barra:<20}] "
              f"(removidas: {len(imagens) - len(selecionadas)})")

    # ==========================================================================
    # RELATÓRIO FINAL
    # ==========================================================================
    total_balanceado = sum(r['selecionadas'] for r in resumo.values())
    total_removidas  = sum(r['removidas']    for r in resumo.values())

    print("\n" + "=" * 60)
    print("RELATÓRIO FINAL")
    print("=" * 60)
    print(f"\n{'Classe':<20} {'Original':>10} {'Final':>8} {'Removidas':>12}")
    print("-" * 54)
    for classe, dados in resumo.items():
        print(f"  {classe:<18} {dados['original']:>10} {dados['selecionadas']:>8} "
              f"{dados['removidas']:>12}")
    print("-" * 54)
    print(f"  {'TOTAL':<18} {total_original:>10} {total_balanceado:>8} {total_removidas:>12}")

    print(f"""
✅ Dataset balanceado criado com sucesso!

📁 Local: {DATASET_BALANCEADO}
📊 Redução total: {total_removidas} imagens removidas 
   ({(total_removidas/total_original*100):.1f}% do dataset original)

⚠️  O dataset ORIGINAL em:
   {DATASET_ORIGINAL}
   permanece INTOCADO — todas as imagens originais estão preservadas.

➡️  Próximo passo: no treino.py, altere a variável:
   caminho_dataset = "{DATASET_BALANCEADO}"
""")


if __name__ == "__main__":
    undersampling_estratificado()