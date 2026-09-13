# Kubernetes Deployment Demo

Proyecto de portfolio enfocado en Kubernetes: despliega una app Flask
mínima (`app.py`, con endpoints `/health` e `/info`) usando los recursos
fundamentales de K8s, aplicados con buenas prácticas reales.

La app es intencionalmente simple porque el foco está en la
**orquestación**, no en la lógica de negocio.

## Conceptos de Kubernetes que muestra este proyecto

| Recurso | Qué resuelve |
|---|---|
| `Namespace` | Aísla los recursos de este proyecto del resto del cluster. |
| `ConfigMap` | Separa la configuración (variables de entorno) de la imagen, sin hardcodear nada. |
| `Deployment` | Mantiene N réplicas del pod corriendo, y las reemplaza automáticamente si fallan. |
| `livenessProbe` | Si la app se cuelga, Kubernetes reinicia el pod solo. |
| `readinessProbe` | Si la app no está lista para recibir tráfico, se la saca temporalmente del balanceo sin reiniciarla. |
| `resources.requests/limits` | Evita que un pod con problemas consuma todos los recursos del nodo. |
| `Service` (NodePort) | Da una dirección estable a los pods, que cambian de IP constantemente. |
| `HorizontalPodAutoscaler` | Escala automáticamente la cantidad de réplicas según el uso de CPU. |

## Estructura

```
k8s-deployment-demo/
├── app.py
├── requirements.txt
├── Dockerfile
├── .dockerignore
└── manifests/
    ├── 00-namespace.yaml
    ├── 01-configmap.yaml
    ├── 02-deployment.yaml
    ├── 03-service.yaml
    └── 04-hpa.yaml
```

Los archivos están numerados porque el orden de aplicación importa: el
namespace tiene que existir antes que los recursos que van adentro.

## Cómo probarlo localmente con Minikube

### 1. Levantar el cluster (si no está corriendo)

```bash
minikube start
```

### 2. Construir la imagen DENTRO del entorno Docker de Minikube

Minikube corre su propio motor de Docker, separado del de tu máquina.
Si buildeás la imagen normalmente, Kubernetes no la va a encontrar. Hay
que apuntar la build al Docker de Minikube:

```bash
eval $(minikube docker-env)          # Linux/Mac
# En Windows PowerShell:
# minikube docker-env | Invoke-Expression

docker build -t demo-app:multi-stage .
```

### 3. Aplicar los manifiestos

```bash
kubectl apply -f manifests/
```

### 4. Verificar que todo esté corriendo

```bash
kubectl get all -n demo-app
```

Deberías ver 2 pods en estado `Running`, el Deployment, el Service y el
HPA (el HPA puede tardar un poco en mostrar métricas).

### 5. Acceder a la app

```bash
minikube service demo-app-service -n demo-app --url
```

Ese comando te da una URL. Con ella:

```bash
curl <url-que-te-dio>/health
curl <url-que-te-dio>/info
```

### 6. Ver el autoescalado en acción (opcional, requiere metrics-server)

```bash
minikube addons enable metrics-server
kubectl get hpa -n demo-app --watch
```

### 7. Simular que un pod se cae

```bash
kubectl get pods -n demo-app
kubectl delete pod <nombre-de-un-pod> -n demo-app
kubectl get pods -n demo-app --watch
```

Vas a ver cómo Kubernetes crea un pod nuevo automáticamente para
mantener las 2 réplicas del Deployment — este es el comportamiento que
vale la pena mostrar y explicar en una entrevista.

## Limpieza

```bash
kubectl delete namespace demo-app
```

Borra todo lo creado (deployment, service, configmap, hpa) de una sola
vez, porque estaban todos dentro del namespace `demo-app`.
