# RUNBOOK EP3 — De donde estás hoy hasta el video entregado

Guía para seguir sin saber nada previo. Cada paso dice **qué abrir, dónde
hacer clic, qué escribir, qué debes ver y qué hacer si falla.**

---

# 📊 ESTADO ACTUAL (verificado el 2026-07-18)

| Paso | Estado | Detalle |
|---|---|---|
| **A1** Subir los 3 repos a GitHub | ✅ **HECHO** | ms-personal-medico, ms-citas y ep3-infraestructura publicados con ramas y tags |
| **A2** Cuenta y token de Docker Hub | ⬜ pendiente | Es tu próximo paso |
| **A3** Secrets en GitHub | ⬜ pendiente | Por eso el pipeline está en rojo (ver abajo) |
| **A4** Crear las 2 máquinas EC2 | ⬜ pendiente | |
| **A5** Formar el clúster Swarm | ⬜ pendiente | |
| **A6** Crear cola SQS + Lambda | ⬜ pendiente | |
| **A7** Desplegar el stack | ⬜ pendiente | |
| **A8** Configurar API Gateway | ⬜ pendiente | |
| **A9** Verificación total | ⬜ pendiente | |
| **B** Pre-vuelo del día de grabar | ⬜ pendiente | |
| **C** Grabación | ⬜ pendiente | Ver `instructivo-video.md` |

**Extras ya resueltos (no los repitas):**
- ✅ Docker Desktop instalado y funcionando en tu PC.
- ✅ Las 2 imágenes Docker construidas y probadas localmente (368 MB y
  389 MB, contenedores `healthy`, endpoints respondiendo, POST de cita
  funcionando entre contenedores). **La escena 2 del video ya está ensayada.**
- ✅ Los 20 tests pasan y **en GitHub el job "Build y pruebas (Maven)" está
  en VERDE** — o sea, la parte de integración continua ya funciona sola.

**Diagnóstico exacto del pipeline hoy:**
```
Build y pruebas (Maven)      -> ✅ success
Imagen Docker a Docker Hub   -> ❌ failure   ← falta el token de Docker Hub (A2+A3)
Despliegue en Docker Swarm   -> ⏭️ skipped   ← no corre porque el anterior falló
```
Esto es **normal y esperado**: se arregla solo cuando completes A2 y A3.

**Tiempo que te queda:** ~2 horas de configuración (A2→A9) + 1 hora de
preparación y rodaje + 1 hora de edición.

---

# ⚠ ANTES DE EMPEZAR: cómo funciona AWS Academy

Lee esto una vez, te ahorra horas de confusión:

- AWS Academy te da un laboratorio que **se apaga solo**. Cada vez que
  trabajes debes entrar y presionar **Start Lab** y esperar el punto 🟢.
- **Las credenciales cambian en cada sesión.** Por eso hay pasos que
  tendrás que repetir cada día que trabajes (están marcados con 🔄).
- **Si detienes las máquinas EC2, al encenderlas cambia su IP pública.** Si
  eso pasa hay que actualizar 2 lugares (te explico dónde en la Fase B).
- **Consejo clave:** intenta hacer A4→A9 en una sola tarde, y graba el
  video al día siguiente o el mismo día. Mientras menos sesiones, menos
  cosas se desconfiguran.

---

# FASE A — Montar todo en la nube (una sola vez, ~2 h)

## ✅ A1. Subir los repos — YA ESTÁ HECHO

No hagas nada. Tus 3 repositorios ya están en GitHub:
- `github.com/Dioocamp/ms-personal-medico`
- `github.com/Dioocamp/ms-citas`
- `github.com/Dioocamp/ep3-infraestructura`

---

## A2. Crear cuenta y token en Docker Hub (5 min)

**Qué es y para qué:** Docker Hub es como un "GitHub de imágenes Docker".
Tu pipeline necesita subir ahí las imágenes para que después el servidor
las descargue. El "token" es una contraseña especial para que GitHub pueda
subirlas por ti.

1. Abre Chrome → escribe `hub.docker.com` → Enter.
2. Si no tienes cuenta: clic en **Sign Up** → correo, usuario y contraseña
   → confirma el correo que te llega.
   Si ya tienes: **Sign In**.
3. **📝 ANOTA TU NOMBRE DE USUARIO EXACTO** (aparece arriba a la derecha).
   Lo necesitarás varias veces. Ejemplo: `dioocamp`.
4. Clic en tu **avatar** (arriba a la derecha) → **Account settings**.
5. En el menú izquierdo: **Personal access tokens** → botón
   **Generate new token**.
6. Rellena:
   - Description: `github-actions`
   - Access permissions: **Read & Write**
   - Clic en **Generate**.
7. 🚨 **Aparece el token una sola vez.** Clic en **Copy** y pégalo
   inmediatamente en un Bloc de notas (tecla Windows → `bloc de notas`).
   Guárdalo con el nombre `datos-ep3.txt` en tu Escritorio — ahí irás
   juntando todos los datos.

👁️ **Debes tener anotado:** tu usuario de Docker Hub y el token
(una cadena larga tipo `dckr_pat_xxxxxxxxxxxx`).

### A2-bis. ¿Tu usuario es distinto de `dioocamp`?

El archivo de configuración asume que tu usuario es `dioocamp`. Si el tuyo
es otro, hay que cambiarlo:

1. Abre **Visual Studio Code** (tecla Windows → `Visual Studio Code`).
2. **File → Open Folder** → navega a
   `C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios`
   → **Seleccionar carpeta**.
3. En el explorador izquierdo: `ep3-infraestructura` → clic en
   `docker-compose.yml`.
4. Presiona **Ctrl+H** (buscar y reemplazar). Arriba escribe `dioocamp/` y
   abajo `TUUSUARIO/`. Clic en el ícono de **reemplazar todo** (las dos
   flechitas). Guarda con **Ctrl+S**.
5. Guárdalo en GitHub: abre PowerShell (tecla Windows → `powershell`) y pega
   esta línea **completa, tal cual** (es una sola línea):
   ```
   cd C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios\ep3-infraestructura ; git add . ; git commit -m "config: usuario de Docker Hub" ; git push
   ```
   > ⚠ En PowerShell, cada comando va en su propia línea **o** separados por
   > `;`. Si pegas `cd ruta` y `git add .` juntos sin el `;`, dará el error
   > *"A positional parameter cannot be found that accepts argument 'git'"*.

---

## A3. Configurar los "secrets" en GitHub (15 min)

**Qué es y para qué:** un *secret* es una contraseña guardada en GitHub que
el pipeline usa sin que quede escrita en el código. Sin ellos, el pipeline
no puede subir imágenes ni entrar al servidor.

> ⚠ **Los secrets `EC2_HOST` y `EC2_SSH_KEY` los tendrás recién después
> del paso A4.** Así que este paso lo harás en **dos visitas**: ahora los
> de Docker Hub, y después de A4 vuelves por el resto. Es normal.

### Cómo se agrega un secret (el procedimiento, lo repetirás varias veces)

1. Entra al repositorio en Chrome, por ejemplo
   `github.com/Dioocamp/ms-citas`.
2. Clic en **Settings** (engranaje, arriba a la derecha del repo).
3. En el menú izquierdo, baja hasta **Secrets and variables** → clic →
   submenú **Actions**.
4. Botón verde **New repository secret**.
5. En **Name** escribe el nombre EXACTO (mayúsculas y guiones bajos
   incluidos). En **Secret** pega el valor.
6. Clic en **Add secret**. Repite para cada uno.

### Ahora agrega estos 2 secrets en LOS 3 REPOSITORIOS

(sí, hay que repetirlo en cada repo: ms-personal-medico, ms-citas y
ep3-infraestructura)

| Name | Secret (valor) |
|---|---|
| `DOCKERHUB_USERNAME` | tu usuario de Docker Hub (paso A2) |
| `DOCKERHUB_TOKEN` | el token largo que copiaste en A2 |

### Después de A4 volverás a agregar estos

| Name | Secret | ¿Dónde? |
|---|---|---|
| `EC2_HOST` | IP pública del manager | los 3 repos |
| `EC2_USER` | escribe: `ec2-user` | los 3 repos |
| `EC2_SSH_KEY` | todo el contenido del archivo .pem | los 3 repos |
| `AWS_ACCESS_KEY_ID` | de AWS Details 🔄 | solo ep3-infraestructura |
| `AWS_SECRET_ACCESS_KEY` | de AWS Details 🔄 | solo ep3-infraestructura |
| `AWS_SESSION_TOKEN` | de AWS Details 🔄 | solo ep3-infraestructura |
| `AWS_REGION` | escribe: `us-east-1` | solo ep3-infraestructura |

---

## A4. Crear las 2 máquinas virtuales EC2 (30 min)

**Qué es y para qué:** EC2 son computadores en la nube de Amazon. Vas a
crear dos: uno será el "jefe" (manager) y otro el "trabajador" (worker).
Entre los dos formarán el clúster que exige la evaluación.

### A4.1 Entrar a AWS

1. Entra a AWS Academy (el sitio del curso) → tu curso → módulo
   **Learner Lab** → botón **Start Lab**.
2. Espera a que el círculo junto a "AWS" se ponga **🟢 verde** (1-2 min).
3. Clic en la palabra **AWS** (arriba a la izquierda) → se abre la consola
   de AWS en una pestaña nueva.

### A4.2 Crear la primera máquina (manager)

1. En la barra de búsqueda de arriba escribe `EC2` → Enter.
2. En el menú izquierdo: **Instances** → botón naranja
   **Launch instances**.
3. **Name:** escribe `swarm-manager`
4. **Application and OS Images:** deja seleccionado **Amazon Linux**
   (debe decir *Amazon Linux 2023 AMI*).
5. **Instance type:** clic en el desplegable → elige **t3.small**.
   (Si no aparece o da error de cuota, usa `t2.small`.)
6. **Key pair (login):** clic en **Create new key pair**:
   - Key pair name: `clinica-key`
   - Type: **RSA**, Format: **.pem**
   - Clic en **Create key pair** → se descarga `clinica-key.pem`.
   - 🚨 **Ese archivo es tu llave para entrar al servidor. NO lo borres.**
     Déjalo en `C:\Users\dinko\Downloads\clinica-key.pem`.
7. **Network settings:** clic en **Edit** (a la derecha):
   - Security group name: borra lo que haya y escribe `clinica-sg`
   - Description: `clinica`
   - Ya hay una regla SSH (puerto 22). Déjala con Source: **Anywhere**
     (0.0.0.0/0) para no tener problemas si cambia tu internet.
   - Clic en **Add security group rule** y agrega estas dos:

   | Type | Port range | Source |
   |---|---|---|
   | Custom TCP | `8081` | Anywhere-IPv4 |
   | Custom TCP | `8082` | Anywhere-IPv4 |

8. Botón naranja **Launch instance** → espera → **View all instances**.

### A4.3 Crear la segunda máquina (worker)

Repite A4.2 con estos cambios:
- **Name:** `swarm-worker`
- **Key pair:** en el desplegable elige la ya creada `clinica-key`
  (¡NO crees otra!).
- **Network settings → Edit → Select existing security group** → marca
  `clinica-sg`.

### A4.4 Abrir los puertos internos del clúster (¡importante!)

Sin esto las dos máquinas no se pueden hablar y el clúster no se forma.

1. Menú izquierdo de EC2 → **Security Groups** → clic en `clinica-sg`.
2. Pestaña **Inbound rules** → botón **Edit inbound rules**.
3. Clic en **Add rule** cuatro veces y completa así (en **Source**, escribe
   `sg-` en el campo de búsqueda y **selecciona el propio `clinica-sg`**):

   | Type | Port range | Source |
   |---|---|---|
   | Custom TCP | `2377` | clinica-sg |
   | Custom TCP | `7946` | clinica-sg |
   | Custom UDP | `7946` | clinica-sg |
   | Custom UDP | `4789` | clinica-sg |

4. Clic en **Save rules**.

### A4.5 Anotar los datos que necesitas

1. Menú izquierdo → **Instances** → clic en **swarm-manager**.
2. En el panel de abajo, copia:
   - **Public IPv4 address** → 📝 anótala como **IP-MANAGER**
   - **Private IPv4 address** → 📝 anótala como **IP-PRIVADA-MANAGER**
3. Clic en **swarm-worker** y verifica que su estado sea *Running*.

### A4.6 Conectarte por primera vez e instalar Docker en AMBAS

**Cómo conectarte (lo harás muchas veces):**

1. Abre PowerShell (tecla Windows → `powershell` → Enter).
2. Escribe (reemplazando la IP por la tuya) y Enter:
   ```
   ssh -i C:\Users\dinko\Downloads\clinica-key.pem ec2-user@IP-MANAGER
   ```
3. Pregunta `Are you sure you want to continue connecting?` → escribe
   `yes` → Enter.

👁️ **Debes ver** que el texto de la izquierda cambia a algo como
`[ec2-user@ip-172-31-25-14 ~]$`. Eso significa que ya estás DENTRO del
servidor: lo que escribas ahora se ejecuta allá, no en tu PC.

🚑 **Si dice "UNPROTECTED PRIVATE KEY FILE":** Windows exige que la llave
sea privada. Ejecuta estas dos líneas en PowerShell y reintenta:
```
icacls C:\Users\dinko\Downloads\clinica-key.pem /inheritance:r
icacls C:\Users\dinko\Downloads\clinica-key.pem /grant:r "dinko:R"
```
🚑 **Si se queda pegado y no responde:** revisa que la instancia esté
*Running* y que la IP sea la actual (cambia al reiniciar la máquina).

**Ya conectado, instala Docker** (copia y pega las 3 líneas de a una):
```
sudo dnf install -y docker git
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
```
Luego escribe `exit` y Enter (te desconecta), y **vuelve a conectarte** con
el mismo comando ssh. Esto es necesario para que tome los permisos.

Verifica que quedó bien:
```
docker ps
```
👁️ Debe mostrar una tabla con títulos (CONTAINER ID, IMAGE...), vacía.
🚑 Si dice "permission denied": no reconectaste. Escribe `exit` y entra de
nuevo.

**🔁 Ahora repite TODO A4.6 para la máquina worker** (mismo comando ssh
pero con la IP pública de swarm-worker).

### A4.7 Volver a GitHub a completar los secrets

Ya tienes los datos que faltaban en A3:

1. `EC2_HOST` = tu **IP-MANAGER** → agrégalo en los **3 repos**.
2. `EC2_USER` = `ec2-user` → en los **3 repos**.
3. `EC2_SSH_KEY`: abre el archivo `clinica-key.pem` con el Bloc de notas
   (clic derecho sobre el archivo → Abrir con → Bloc de notas) →
   **Ctrl+A** (seleccionar todo) → **Ctrl+C** (copiar) → pégalo como valor
   del secret en los **3 repos**. Debe incluir las líneas
   `-----BEGIN RSA PRIVATE KEY-----` y `-----END RSA PRIVATE KEY-----`.

### A4.8 Poner el pipeline en verde 🎉

1. Ve a `github.com/Dioocamp/ms-citas` → pestaña **Actions**.
2. Clic en la ejecución más reciente (la que tiene ✗ roja).
3. Botón **Re-run all jobs** (arriba a la derecha) → **Re-run jobs**.
4. Espera 4-6 minutos refrescando con **F5**.

👁️ **Los 3 jobs deben quedar con ✓ verde.** Además, en hub.docker.com →
**Repositories** debe aparecer `ms-citas`.
🚑 Si `Imagen Docker a Docker Hub` sigue rojo → el token está mal copiado:
regenera uno nuevo en Docker Hub y actualiza el secret.
🚑 Si `Despliegue en Docker Swarm` falla → es normal por ahora: el clúster
todavía no existe (lo creas en A5). Después de A7 lo vuelves a correr.

**Repite el Re-run en `ms-personal-medico`.**

---

## A5. Formar el clúster Swarm (10 min)

**Qué es y para qué:** Docker Swarm hace que tus dos servidores trabajen
como si fueran uno solo, repartiendo copias (réplicas) de tus
microservicios. Es lo que evalúa el IE7.

### En el MANAGER

1. Conéctate por ssh al manager (ver A4.6).
2. Descarga tu repositorio de infraestructura:
   ```
   git clone https://github.com/Dioocamp/ep3-infraestructura.git
   cd ep3-infraestructura
   ```
3. Inicia el clúster:
   ```
   bash scripts/init-swarm.sh
   ```

👁️ **Vas a ver** un texto que dice `Swarm initialized` y más abajo un
comando largo que empieza con `docker swarm join --token SWMTKN-...`.
📋 **Selecciona ese comando completo con el mouse y cópialo** (en
PowerShell, seleccionar ya copia; también puedes hacer clic derecho).
Pégalo en tu `datos-ep3.txt` por si acaso.

### En el WORKER

4. Abre **otra ventana** de PowerShell y conéctate al worker:
   ```
   ssh -i C:\Users\dinko\Downloads\clinica-key.pem ec2-user@IP-DEL-WORKER
   ```
5. Pega el comando `docker swarm join --token ...` que copiaste → Enter.

👁️ **Debe responder:** `This node joined a swarm as a worker.`
🚑 Si se queda pegado o dice *timeout*: faltan las reglas de puertos del
paso **A4.4** (2377, 7946, 4789 con origen el propio security group).

### Verificar

6. Vuelve a la ventana del **manager** y escribe:
   ```
   docker node ls
   ```
👁️ **Debes ver 2 líneas**, ambas con STATUS `Ready`: una con MANAGER STATUS
`Leader` (el manager) y otra con esa columna vacía (el worker).

---

## A6. Crear la cola SQS y la función Lambda (10 min) 🔄

**Qué es y para qué:** la cola SQS es un "buzón de mensajes" y la Lambda es
un programa que se ejecuta solo cuando llega un mensaje. Cubren IE5, IE10,
IE11, IE13 y IE14. El script los crea todos automáticamente.

### A6.1 Copiar tus credenciales de AWS al servidor 🔄

*(Este paso lo repetirás cada vez que inicies una nueva sesión de Academy.)*

1. En la ventana de AWS Academy (donde está el Start Lab), clic en
   **AWS Details** (arriba a la derecha) → clic en **Show** junto a
   *AWS CLI*.
2. Aparece un bloque de texto que empieza con `[default]`. **Selecciónalo
   todo y cópialo** (Ctrl+C).
3. En la ventana ssh del **manager**, escribe:
   ```
   mkdir -p ~/.aws
   nano ~/.aws/credentials
   ```
4. Se abre un editor de texto azul dentro de la terminal. **Pega** con
   **clic derecho** (o Ctrl+Shift+V).
5. Guardar y salir: presiona **Ctrl+O** → **Enter** → **Ctrl+X**.

👁️ Para verificar que quedó bien:
```
aws sts get-caller-identity
```
Debe devolver un JSON con tu número de cuenta.
🚑 Si dice *ExpiredToken*: copiaste credenciales viejas → repite desde el
punto 1 con el lab iniciado.

### A6.2 Ejecutar el script que crea todo

```
cd ~/ep3-infraestructura
bash infra/provision.sh
```

👁️ **Vas a ver** tres pasos: `[1/3]` cola lista, `[2/3]` función creada,
`[3/3]` trigger creado. Y al final una línea:
```
QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/clinica-citas-queue
```
📝 **COPIA esa URL completa** a tu `datos-ep3.txt`. La necesitas en A7.

🚑 Si dice `role/LabRole does not exist`: estás fuera de AWS Academy; en
ese caso hay que crear un rol IAM con permisos de Lambda + SQS.

---

## A7. Poner en marcha tus microservicios en el clúster (15 min)

### A7.1 Rellenar los 3 datos en el archivo de configuración

1. En tu PC, abre **Visual Studio Code** con la carpeta del proyecto.
2. Abre `ep3-infraestructura` → `docker-compose.yml`.
3. Cambia estos tres valores (usa **Ctrl+F** para encontrarlos):

   | Buscar | Reemplazar por |
   |---|---|
   | `dioocamp/` | tu usuario de Docker Hub (si es distinto) |
   | `https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/clinica-citas-queue` | la QUEUE_URL completa de A6 |
   | `cambiar-por-un-secreto-largo` (aparece **2 veces**) | inventa una contraseña larga sin espacios, ej: `ClinicaEP3-Gateway-2026-xyz` |

   📝 **Anota ese secreto del gateway** en `datos-ep3.txt`: lo usarás en A8.
   ⚠ Debe quedar **idéntico en los dos lugares** donde aparece.

4. **Ctrl+S** para guardar.
5. Súbelo a GitHub. En PowerShell, pega esta línea completa:
   ```
   cd C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios\ep3-infraestructura ; git add . ; git commit -m "config: cola SQS y secreto del gateway" ; git push
   ```

### A7.2 Desplegar

En la ventana ssh del **manager**:
```
cd ~/ep3-infraestructura
git pull
bash scripts/deploy-stack.sh
```

👁️ Verás `Creating service clinica_mysql`, `clinica_ms-citas`, etc.

### A7.3 Darle a los microservicios acceso a AWS 🔄

```
bash scripts/actualizar-credenciales-aws.sh
```
👁️ Debe decir que actualizó el servicio.

### A7.4 Verificar (¡ten paciencia aquí!)

```
docker service ls
```

👁️ **Lo que buscas:** `clinica_mysql 1/1`, `clinica_ms-citas 2/2`,
`clinica_ms-personal-medico 2/2`.

⏳ **La primera vez tarda 3-5 minutos** y verás `0/2` un buen rato: las
máquinas están descargando las imágenes y MySQL se está inicializando. Los
microservicios se reinician solos hasta que la base esté lista — **eso es
normal, no es un error.** Repite `docker service ls` cada minuto.

Cuando esté en 2/2, prueba:
```
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
```
👁️ Ambos deben responder `{"status":"UP",...}`.

🚑 Si tras 6 minutos sigue en 0/2:
```
docker service ps clinica_ms-citas --no-trunc
```
Lee la columna ERROR. Si dice `No such image` → la imagen no está en Docker
Hub: vuelve a A4.8 y verifica que el pipeline haya quedado verde.

---

## A8. Configurar el API Gateway (40 min, todo en la consola AWS)

**Qué es y para qué:** el API Gateway es la puerta de entrada única a tu
sistema. Exige una clave para dejar pasar y protege tus servidores. Es el
IE12.

📖 **El paso a paso completo y detallado está en el archivo
`infra/api-gateway.md`** (secciones §1 a §5). Ábrelo en GitHub o en VS Code
y síguelo tal cual.

**Resumen de lo que harás ahí:**
1. Crear una **REST API** llamada `clinica-gateway`.
2. Crear **8 rutas** que apuntan a `http://IP-MANAGER:8081` y `:8082`
   (`/api/citas`, `/api/medicos`, `/api/pacientes`, `/api/especialidades` y
   sus versiones `{proxy+}`).
3. En cada método, agregar la cabecera `x-gateway-secret` con el secreto
   que inventaste en A7.
4. Marcar **API key required** en cada método, crear la key `clinica-key` y
   el plan de uso `clinica-plan`.
5. **Deploy API** al stage `prod`.

📝 **Al terminar anota en `datos-ep3.txt`:**
- La **Invoke URL** (algo como
  `https://ab12cd34.execute-api.us-east-1.amazonaws.com/prod`)
- El **valor de la API key** (API Gateway → API keys → clinica-key → Show)

⚠ **Regla de oro del Gateway:** cada vez que cambies algo (una ruta, una
cabecera, la IP), tienes que hacer **Deploy API** otra vez o el cambio no
tiene efecto.

---

## A9. Verificación total (15 min) — el momento de la verdad

Abre PowerShell en tu PC y **define tus datos** (reemplaza con los tuyos):
```
$env:GW  = "https://TU-ID.execute-api.us-east-1.amazonaws.com/prod"
$env:KEY = "TU-API-KEY"
$env:IP  = "IP-MANAGER"
```

### A9.1 Las tres respuestas que prueban el IE12

```
curl.exe -i "$env:GW/api/medicos"
```
👁️ `HTTP/1.1 403 Forbidden` ← el Gateway bloquea sin clave ✔

```
curl.exe -i -H "x-api-key: $env:KEY" "$env:GW/api/medicos"
```
👁️ `HTTP/1.1 200 OK` ← con clave sí pasa ✔

```
curl.exe -i "http://$($env:IP):8081/api/medicos"
```
👁️ `HTTP/1.1 401` ← el servidor rechaza el acceso directo ✔

🚑 Si el segundo da **500 o 502**: la IP del manager en el Gateway está
mala → corrige las integraciones y haz **Deploy API**.
🚑 Si el segundo da **403**: la key no está asociada al plan de uso, o
falta el Deploy API.

### A9.2 Crear los datos de ejemplo

Pega estas tres líneas de a una:
```
curl.exe -s -X POST "$env:GW/api/especialidades" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"nombre\":\"Cardiologia\",\"descripcion\":\"Especialidad del corazon\"}'
```
```
curl.exe -s -X POST "$env:GW/api/medicos" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"rut\":\"15111222-3\",\"nombre\":\"Carla\",\"apellido\":\"Soto\",\"email\":\"carla@clinica.cl\",\"registroSuperintendencia\":\"SIS-2001\",\"especialidadId\":1}'
```
```
curl.exe -s -X POST "$env:GW/api/pacientes" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"rut\":\"12345678-5\",\"nombre\":\"Ana\",\"apellido\":\"Rojas\",\"email\":\"ana@mail.cl\",\"telefono\":\"+56933333333\",\"fechaNacimiento\":\"1992-08-15\"}'
```
👁️ Cada uno devuelve un JSON con el registro creado y su `id`.

### A9.3 La prueba end-to-end (IE14 + IE15)

```
curl.exe -i -X POST "$env:GW/api/citas" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"fecha\":\"2026-08-20\",\"hora\":\"10:30\",\"motivo\":\"Control cardiologico\",\"medicoId\":1,\"pacienteId\":1}'
```
👁️ `HTTP/1.1 201` y un JSON con `"estado":"PROGRAMADA"`.

Ahora, en la ventana ssh del **manager**:
```
aws logs tail /aws/lambda/clinica-notificador --since 5m
```
👁️ **Debe aparecer** una línea con `"evento": "notificacion_enviada"` y el
mensaje «Estimado/a Ana Rojas...». Tarda entre 5 y 15 segundos; si sale
vacío, espera y repite el comando.

🚑 Si no aparece nunca: las credenciales del microservicio están vencidas →
`bash scripts/actualizar-credenciales-aws.sh`, espera 1 minuto, repite el
POST y vuelve a mirar el log.

🎉 **Si llegaste hasta aquí con todo en verde, tu sistema completo funciona
y puedes grabar el video.**

---

# FASE B — Pre-vuelo el día de grabar (30 min antes)

Haz esto **siempre**, aunque ayer funcionara todo. Marcados 🔄 los que
cambian por sesión.

1. 🔄 **AWS Academy → Start Lab** → espera el 🟢.
2. 🔄 **¿Cambió la IP del manager?** Consola EC2 → Instances →
   swarm-manager → Public IPv4.
   - **Si cambió**, actualiza en 2 lugares:
     a) Secret `EC2_HOST` en los 3 repos de GitHub.
     b) Las 8 integraciones del API Gateway (`infra/api-gateway.md` §2) y
        después **Deploy API**.
3. 🔄 **Secrets AWS frescos** en el repo ep3-infraestructura
   (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` desde
   *AWS Details*).
4. 🔄 **Credenciales en el manager:** ssh → `nano ~/.aws/credentials` →
   pegar las nuevas → Ctrl+O, Enter, Ctrl+X → y luego:
   ```
   cd ~/ep3-infraestructura && bash scripts/actualizar-credenciales-aws.sh
   ```
5. **Clúster sano:** `docker node ls` (2 Ready) y `docker service ls`
   (1/1 y 2/2). Si algo está en 0/2 espera 2 minutos.
6. **Datos de ejemplo presentes:**
   `curl.exe -H "x-api-key: $env:KEY" "$env:GW/api/medicos"` → debe listar a
   Carla Soto. Si viene vacío, vuelve a A9.2.
7. **Ensayo en seco:** ejecuta todos los comandos de la grabación una vez
   SIN grabar. Si todos responden bien, recién ahí grabas.
8. **Prepara las 5 ventanas** (detalle completo en `instructivo-video.md`,
   Parte 1).
9. **Docker Desktop** abierto en tu PC (ballena quieta en la barra).
10. **Audífonos con micrófono** puestos y pieza en silencio.

---

# FASE C — Grabar el video

👉 **Todo el detalle está en `docs/instructivo-video.md`**: cómo instalar
OBS, cómo dejar las ventanas, y las 10 escenas con cada comando, lo que
debes ver, el plan B, y el texto exacto que debes narrar.

Resumen de las 10 escenas (≈7 minutos):

| # | Escena | Qué muestras | IE |
|---|---|---|---|
| 1 | Intro | Diagrama de arquitectura | IE16 |
| 2 | Docker local | build + run + curl a endpoints | IE2 |
| 3 | Compose + Swarm | El YAML y `docker node/service ls` | IE3, IE7 |
| 4 | Pipeline | commit → Actions verde → nube responde | IE6 |
| 5 | Escalado | `scale` a 4, a 1, a 2 sin caídas | IE8 |
| 6 | Justificación | Decisiones técnicas del README | IE9 |
| 7 | Cola SQS | Consola SQS + propósito | IE11 |
| 8 | API Gateway | 403 → 200 → 401 | IE12 |
| 9 | Lambda | Código + trigger SQS | IE13 |
| 10 | End-to-end | POST cita → log de la Lambda + cierre | IE15, IE14 |

---

# 🚑 TABLA DE PROBLEMAS Y SOLUCIONES

| Lo que ves | Por qué pasa | Cómo se arregla |
|---|---|---|
| Réplicas en `0/2` reiniciándose | MySQL todavía está inicializando | Espera 2-3 min; `docker service ps <servicio>` para confirmar |
| `No such image` en `service ps` | La imagen no está en Docker Hub | Revisa que el pipeline (A4.8) esté verde |
| Pipeline rojo en "Imagen Docker" | Token de Docker Hub malo | Regenera el token y actualiza el secret |
| Pipeline rojo en "Despliegue" | Clave SSH mal copiada o clúster caído | Revisa `EC2_SSH_KEY` (debe incluir BEGIN y END) |
| Pipeline rojo en "provision-cloud" | Credenciales de Academy vencidas | Actualiza los 3 secrets AWS y Re-run |
| `500`/`502` desde el Gateway | La IP del manager cambió | Corrige integraciones + **Deploy API** |
| `403` aun usando la API key | Falta Deploy API o la key no está en el plan | Deploy API; revisa el usage plan |
| POST da 201 pero la Lambda no loguea | Credenciales del microservicio vencidas | `bash scripts/actualizar-credenciales-aws.sh` |
| `curl` local no responde | El contenedor aún está arrancando | Espera 20 s; `docker logs <nombre>` |
| El worker no se une al clúster | Puertos 2377/7946/4789 cerrados | Revisa A4.4 (origen = el propio SG) |
| `UNPROTECTED PRIVATE KEY FILE` | Permisos del .pem en Windows | Los dos comandos `icacls` de A4.6 |
| `ExpiredToken` en AWS CLI | Sesión de Academy vencida | Start Lab y copiar credenciales nuevas |

---

# 📋 CHECKLIST FINAL DE ENTREGA

- [ ] Correo al docente confirmando que entregas individual.
- [ ] Pestaña **Actions** en verde en los 3 repos (última ejecución).
- [ ] Video en mp4, entre 3 y 8 minutos, con tu voz clara.
- [ ] Video subido al **AVA** + enviado al correo del docente.
- [ ] Los **3 enlaces de GitHub** en el AVA + en el mismo correo:
  - `github.com/Dioocamp/ms-personal-medico`
  - `github.com/Dioocamp/ms-citas`
  - `github.com/Dioocamp/ep3-infraestructura`
