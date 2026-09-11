from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def root():
    """Health CheckPoint"""

    return {"status": "ok"}
