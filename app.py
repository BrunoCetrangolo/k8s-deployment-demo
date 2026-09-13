"""
app.py

App Flask mínima, a propósito simple. El objetivo de este proyecto
no es la lógica de negocio, sino mostrar cómo optimizar la imagen
Docker que la empaqueta (ver Dockerfile y README).
"""

import os
import time
from datetime import datetime

from flask import Flask, jsonify

app = Flask(__name__)
START_TIME = time.time()


@app.route("/health")
def health():
    """Endpoint típico de healthcheck: usado por load balancers,
    orquestadores (Kubernetes, ECS) o monitoreo para saber si el
    contenedor está vivo y respondiendo."""
    uptime_seconds = round(time.time() - START_TIME, 2)
    return jsonify({
        "status": "ok",
        "uptime_seconds": uptime_seconds,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    })


@app.route("/info")
def info():
    """Devuelve información del entorno de ejecución: útil para
    verificar, por ejemplo, qué versión de la imagen está corriendo
    en cada ambiente sin tener que entrar al contenedor a mano."""
    return jsonify({
        "app": "docker-multistage-optimization",
        "version": os.environ.get("APP_VERSION", "dev"),
        "python_env": os.environ.get("FLASK_ENV", "production"),
        "hostname": os.environ.get("HOSTNAME", "unknown"),
    })


@app.route("/")
def root():
    return jsonify({
        "message": "App de demostración de Docker multi-stage build",
        "endpoints": ["/health", "/info"],
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
