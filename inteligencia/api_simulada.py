from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="API Agro TCC - Nuvem", version="1.0.0")

class LaudoFlutter(BaseModel):
    talhao: str
    doenca_identificada: str
    confianca_ia: float
    latitude: float
    longitude: float

@app.post("/api/v1/sincronizar_laudo")
def receber_laudo_do_app(laudo: LaudoFlutter):
    print(f"Recebi um laudo da doença {laudo.doenca_identificada} no talhão {laudo.talhao}!")
    
    return {
        "mensagem": "Sucesso! Laudo salvo na nuvem da nossa startup.",
        "dados_recebidos": laudo
    }

@app.get("/api/v1/status")
def checar_status_servidor():
    return {"status": "Servidor online e aguardando fotos da Soja!"}