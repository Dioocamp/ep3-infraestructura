# Guion del video EP3 (7:30 min, dos narradores)

**Narradores:** N1 = Dinko, N2 = compañero/a. Se alternan por bloque
(la pauta exige la voz de ambos). Grabar las demos primero, narrar encima
después si el audio en vivo sale con ruido (IE17).

**Regla de oro:** cada bloque muestra EN PANTALLA lo que la narración dice.
No leer corriendo: el tiempo está calculado para hablar a ritmo normal.

---

## 0:00–0:30 — Introducción y arquitectura (IE16) — N1

*Pantalla: lámina única con el diagrama de arquitectura del README.*

> «Hola, somos Dinko Ocampo y [NOMBRE]. En esta evaluación desplegamos en la
> nube el sistema de microservicios de nuestra clínica: dos servicios Spring
> Boot orquestados con Docker Swarm sobre dos instancias EC2, un pipeline
> CI/CD con GitHub Actions, y una arquitectura serverless con API Gateway,
> una cola SQS y una función Lambda. Veamos primero cómo se construyen los
> contenedores.»

## 0:30–1:30 — Contenedores locales y endpoints (IE2) — N2

*Pantalla: terminal local.*

```bash
docker build -t ms-personal-medico ./ms-personal-medico
docker build -t ms-citas ./ms-citas
docker network create clinica-local
docker run -d --name personal --network clinica-local -p 8081:8081 -e SPRING_PROFILES_ACTIVE=h2 ms-personal-medico
docker run -d --name citas --network clinica-local -p 8082:8082 -e SPRING_PROFILES_ACTIVE=h2 -e MS_PERSONAL_MEDICO_URL=http://personal:8081 ms-citas
curl http://localhost:8081/api/medicos
curl http://localhost:8082/api/citas
curl http://localhost:8081/actuator/health
```

> «Cada microservicio tiene un Dockerfile multi-stage: una etapa compila con
> Maven y otra ejecuta solo el JAR sobre un JRE Alpine, con usuario no root y
> health check integrado. La imagen final es liviana y reproducible.
> Construimos ambas imágenes, levantamos los contenedores y validamos los
> endpoints: médicos responde en el puerto 8081, citas en el 8082, y el
> health check reporta estado UP.»

## 1:30–2:30 — Compose + despliegue en Swarm (IE3, IE7) — N1

*Pantalla: docker-compose.yml en el editor; luego terminal SSH del manager.*

> «El docker-compose, en versión 3.8 compatible con Swarm, define los dos
> microservicios con dos réplicas cada uno, política de reinicio ante fallos,
> límites de CPU y memoria, y una red overlay que comunica los contenedores
> entre nodos. Las imágenes vienen de Docker Hub, publicadas por el pipeline.»

```bash
docker node ls                    # manager y worker Ready
bash scripts/deploy-stack.sh
docker service ls                 # replicas 2/2
docker service ps clinica_ms-citas
```

> «Nuestro clúster tiene un nodo manager y un worker unidos con los scripts
> del repositorio. Al desplegar el stack, Swarm distribuye las réplicas entre
> ambos nodos, como se ve acá: hay réplicas de citas corriendo en el manager
> y en el worker.»

## 2:30–3:30 — Pipeline CI/CD en acción (IE6) — N2

*Pantalla: VS Code con un cambio trivial visible; terminal; pestaña Actions.*

```bash
git commit -am "feat: version visible en el endpoint de salud" && git push
```

> «Ahora el ciclo completo de integración y despliegue continuo. Hacemos un
> commit y push a main... y GitHub Actions dispara el pipeline: primera
> etapa, build y pruebas con Maven, que publica el reporte de tests como
> artefacto para trazabilidad; segunda, construye la imagen Docker y la sube
> a Docker Hub con dos tags, latest y el SHA del commit; tercera, se conecta
> por SSH al manager y actualiza el servicio en Swarm con la imagen nueva,
> sin intervención manual. El endpoint en la nube ya responde con el cambio
> desplegado.»

*Mostrar: las 3 etapas en verde + curl al endpoint en la nube.*

## 3:30–4:15 — Escalabilidad dinámica (IE8) — N1

*Pantalla: terminal SSH del manager, con un `watch curl` en otra ventana.*

```bash
docker service scale clinica_ms-citas=4
docker service ps clinica_ms-citas
docker service scale clinica_ms-citas=1
docker service scale clinica_ms-citas=2
```

> «Simulemos un aumento de demanda: escalamos citas de dos a cuatro réplicas
> con un solo comando. Swarm programa las nuevas réplicas en ambos nodos y el
> servicio nunca deja de responder, como muestra la petición en paralelo.
> Ante baja demanda escalamos hacia abajo a una réplica, y el sistema sigue
> disponible. Volvemos a dos, nuestro estado normal.»

## 4:15–5:00 — Justificación técnica (IE9) — N2

*Pantalla: sección "Decisiones técnicas" del README, o lámina resumen.*

> «Las decisiones del clúster responden a tres requisitos. Escalabilidad:
> los microservicios son sin estado, así que las réplicas se ajustan en
> segundos y la red overlay balancea las peticiones entre nodos.
> Disponibilidad: con dos nodos y política de reinicio ante fallos, la caída
> de un contenedor —o de un nodo completo— no interrumpe el servicio, y el
> update start-first despliega sin downtime. Mantenibilidad: las imágenes se
> versionan por SHA de commit, lo que hace cada despliegue trazable y el
> rollback trivial, y toda la configuración vive en variables de entorno,
> nunca en el código.»

## 5:00–5:40 — Cola SQS (IE11) — N1

*Pantalla: consola AWS → SQS → clinica-citas-queue.*

> «Esta es la cola clinica-citas-queue, creada de forma idempotente por la
> etapa de provisión del pipeline. Su propósito es desacoplar el agendamiento
> de la notificación al paciente: crear la cita es síncrono y crítico;
> notificar es asíncrono y tolerante a fallos. Si el consumidor está caído,
> los mensajes esperan en la cola y no se pierde ninguna notificación, con
> reintentos automáticos por lote parcial.»

## 5:40–6:15 — API Gateway (IE12) — N2

*Pantalla: consola API Gateway (recursos + usage plan); luego terminal.*

```bash
curl -i "$GW/api/medicos"                      # 403: sin API key
curl -i -H "x-api-key: ***" "$GW/api/medicos"  # 200
curl -i "http://IP:8081/api/medicos"           # 401: acceso directo bloqueado
```

> «Todo el acceso externo entra por API Gateway. La protección tiene dos
> capas: el Gateway exige una API key con plan de uso y throttling —sin ella,
> 403—, y además inyecta una cabecera secreta hacia el backend, que un filtro
> en ambos microservicios valida. Por eso el acceso directo a la instancia
> devuelve 401: el Gateway es la única puerta de entrada al sistema.»

## 6:15–6:45 — Lambda + trigger SQS (IE13, IE14) — N1

*Pantalla: código lambda_function.py; consola Lambda mostrando el trigger.*

> «El consumidor de la cola es la función serverless clinica-notificador,
> en Python. Recibe los lotes del trigger SQS, valida el contrato del mensaje
> y registra la notificación con logging estructurado. Si un mensaje del lote
> falla, devuelve batchItemFailures y SQS reintenta solo ese mensaje: manejo
> parcial de errores, una buena práctica de FaaS.»

## 6:45–7:30 — Prueba end-to-end + cierre (IE15, IE16) — N2, luego N1

*Pantalla: terminal con el guion de docs/prueba-e2e.md.*

```bash
curl -i -X POST "$GW/api/citas" -H "x-api-key: ***" -H "Content-Type: application/json" -d '{...}'   # 201
aws logs tail /aws/lambda/clinica-notificador --since 2m    # notificacion_enviada
```

> N2: «La prueba completa: agendamos una cita como cliente externo, por el
> Gateway. Citas valida el médico contra personal-médico, persiste en MySQL
> y publica el evento en SQS... y en los logs de CloudWatch la Lambda ya
> registró la notificación a la paciente. Petición externa, microservicios,
> cola y serverless: el flujo completo, funcionando en la nube.»

> N1: «En resumen: contenedores optimizados, orquestación con réplicas y
> tolerancia a fallos, despliegue continuo sin intervención manual y una
> arquitectura asíncrona y serverless que escala. Gracias por ver.»

---

## Checklist de grabación

- [ ] Sesión de AWS Academy iniciada + secrets de GitHub actualizados +
      `actualizar-credenciales-aws.sh` ejecutado (¡antes de grabar!).
- [ ] Datos base creados (especialidad, médico, paciente) — ver prueba-e2e.md.
- [ ] Audífonos con micrófono; ambiente silencioso; volumen parejo (IE17).
- [ ] Ambas voces presentes (obligatorio); alternarse por bloque.
- [ ] Duración final entre 3 y 8 minutos (objetivo 7:30).
- [ ] Exportar en mp4 (Kaltura, Canva o Teams sugeridos por la pauta).
