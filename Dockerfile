# ==========================================================
# ETAPA 1: builder
# Imagen completa de Python, con todo lo necesario para
# instalar dependencias (incluso las que requieren compilar
# extensiones en C). Esta etapa NUNCA llega a producción.
# ==========================================================
FROM python:3.12 AS builder

WORKDIR /app

# Copiamos primero requirements.txt solamente: si el código
# cambia pero las dependencias no, Docker reutiliza esta capa
# del cache y no vuelve a instalar nada. Esto acelera mucho
# los builds en CI.
COPY requirements.txt .

RUN pip install --user --no-cache-dir -r requirements.txt


# ==========================================================
# ETAPA 2: runtime
# Imagen "slim": sin compiladores, sin headers de desarrollo,
# solo el intérprete de Python y lo mínimo para correr.
# ==========================================================
FROM python:3.12-slim

WORKDIR /app

# Usuario sin privilegios. Correr contenedores como root es
# una mala práctica de seguridad: si alguien compromete la
# app, no queremos que tenga privilegios de root del sistema.
RUN useradd -m appuser

# Traemos SOLO las dependencias ya instaladas desde builder,
# con el dueño correcto para que appuser pueda ejecutarlas.
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copiamos el código de la app
COPY --chown=appuser:appuser app.py .

ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0

USER appuser

EXPOSE 5000

# Gunicorn en vez del servidor de desarrollo de Flask:
# esto también forma parte de "hacerlo bien", no solo
# de que funcione.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
