# API Gateway — configuración paso a paso (IE12)

El API Gateway es la **única puerta de entrada** al backend. La protección
tiene dos capas:

1. **API Key + Usage Plan** en el Gateway: sin la cabecera `x-api-key`
   el Gateway responde `403 Forbidden` y la petición nunca llega al backend.
2. **Cabecera secreta `x-gateway-secret`**: el Gateway la inyecta en cada
   integración; el filtro `GatewaySecretFilter` de ambos microservicios
   rechaza con `401 Unauthorized` cualquier acceso directo a la IP:puerto
   que no traiga ese valor. Así **todos** los componentes del backend quedan
   protegidos aunque sus puertos sean visibles.

> Se usa **REST API** (no HTTP API) porque las API Keys y los Usage Plans
> solo existen en REST API.

## 1. Crear la API

Consola AWS → **API Gateway** → *Create API* → **REST API** → *Build*:

- API name: `clinica-gateway`
- Endpoint type: **Regional**

## 2. Crear los recursos y métodos (proxy hacia el Swarm)

Para cada microservicio se crea un recurso raíz + un recurso greedy `{proxy+}`.
`IP_PUBLICA` es la IP pública del nodo manager (o cualquier nodo: la malla de
enrutamiento de Swarm responde en todos).

| Recurso en el Gateway | Método | Integración (HTTP proxy) |
|---|---|---|
| `/api/citas` | ANY | `http://IP_PUBLICA:8082/api/citas` |
| `/api/citas/{proxy+}` | ANY | `http://IP_PUBLICA:8082/api/citas/{proxy}` |
| `/api/pacientes` | ANY | `http://IP_PUBLICA:8082/api/pacientes` |
| `/api/pacientes/{proxy+}` | ANY | `http://IP_PUBLICA:8082/api/pacientes/{proxy}` |
| `/api/medicos` | ANY | `http://IP_PUBLICA:8081/api/medicos` |
| `/api/medicos/{proxy+}` | ANY | `http://IP_PUBLICA:8081/api/medicos/{proxy}` |
| `/api/especialidades` | ANY | `http://IP_PUBLICA:8081/api/especialidades` |
| `/api/especialidades/{proxy+}` | ANY | `http://IP_PUBLICA:8081/api/especialidades/{proxy}` |

Pasos por recurso (ejemplo `/api/citas`):

1. *Create resource* → Resource path `/api`, luego dentro `citas`.
2. *Create method* → **ANY** → Integration type **HTTP** → ✔ *HTTP proxy
   integration* → Endpoint URL `http://IP_PUBLICA:8082/api/citas`.
3. Para el greedy: *Create resource* → ✔ *Configure as proxy resource* →
   Resource path `{proxy+}` → Endpoint URL
   `http://IP_PUBLICA:8082/api/citas/{proxy}`.

## 3. Inyectar la cabecera secreta hacia el backend

En **cada método** → *Integration request* → *Edit* → **URL request headers
parameters** → *Add request header parameter*:

- Name: `x-gateway-secret`
- Mapped from: `'EL-MISMO-VALOR-DE-GATEWAY_SECRET-DEL-COMPOSE'`
  (entre comillas simples: es un valor estático)

Con esto el backend solo acepta tráfico que pasó por el Gateway.

## 4. Exigir API Key

1. En **cada método** → *Method request* → *Edit* → **API key required: ✔**.
2. *API keys* (menú izquierdo) → *Create API key* → nombre `clinica-key` →
   guardar el valor.
3. *Usage plans* → *Create* → nombre `clinica-plan`
   - Throttling: rate 10 req/s, burst 20 (control de acceso adicional)
   - *Add API stage* → la API y el stage `prod` (después del paso 5)
   - *Add API key* → `clinica-key`

## 5. Desplegar

*Deploy API* → Stage: `prod`. La URL queda:

```
https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod
```

> Cada cambio en recursos/métodos requiere un nuevo *Deploy API* al stage.

## 6. Verificación (grabar para el video)

```bash
GW="https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod"
IP="IP_PUBLICA_DEL_MANAGER"

# a) Sin API key -> 403 Forbidden (bloquea el Gateway)
curl -i "$GW/api/medicos"

# b) Con API key -> 200 OK (flujo completo autorizado)
curl -i -H "x-api-key: VALOR_DE_LA_KEY" "$GW/api/medicos"

# c) Acceso directo al backend -> 401 Unauthorized (bloquea el filtro)
curl -i "http://$IP:8081/api/medicos"
curl -i "http://$IP:8082/api/citas"

# d) POST de una cita a traves del Gateway -> 201 Created
curl -i -X POST "$GW/api/citas" \
  -H "x-api-key: VALOR_DE_LA_KEY" \
  -H "Content-Type: application/json" \
  -d '{"fecha":"2026-08-20","hora":"10:30","motivo":"Control anual","medicoId":1,"pacienteId":1}'
```

Resultado esperado: solo el camino "Gateway + API key" llega al backend;
los otros dos quedan bloqueados por capas distintas (Gateway y filtro).

## 7. Security Group (defensa en profundidad)

En el Security Group de las EC2:

| Puerto | Origen | Motivo |
|---|---|---|
| 22 (SSH) | Solo tu IP | administración y pipeline |
| 2377, 7946 (TCP/UDP), 4789 (UDP) | El propio Security Group | tráfico interno de Swarm |
| 8081, 8082 | 0.0.0.0/0 | integración del Gateway (protegidos por el filtro `x-gateway-secret`) |

El acceso anónimo a 8081/8082 responde siempre `401`: el filtro convierte
esos puertos en superficies inertes sin la cabecera del Gateway.
