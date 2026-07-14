"""Funcion serverless 'clinica-notificador' (AWS Lambda, Python 3.12).

Consume los eventos CITA_CREADA que ms-citas publica en la cola SQS
'clinica-citas-queue' y registra la notificacion al paciente con
logging estructurado (JSON) en CloudWatch Logs.

Buenas practicas FaaS aplicadas:
- Respuesta parcial por lotes (batchItemFailures): si un mensaje del
  lote falla, SOLO ese mensaje vuelve a la cola; el resto se confirma.
- Validacion del contrato del mensaje antes de procesarlo.
- Logging estructurado en JSON para filtrar en CloudWatch Logs Insights.
- Funcion sin estado: todo el contexto viaja en el mensaje.
"""

import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CAMPOS_OBLIGATORIOS = ("idCita", "rutPaciente", "nombrePaciente", "fechaHora")


def lambda_handler(event, context):
    """Punto de entrada: recibe un lote de mensajes desde el trigger SQS."""
    fallidos = []

    for record in event.get("Records", []):
        try:
            _procesar_mensaje(record)
        except Exception as error:  # noqa: BLE001 - el mensaje fallido se reintenta via SQS
            logger.error(json.dumps({
                "evento": "error_procesamiento",
                "messageId": record.get("messageId"),
                "detalle": str(error),
            }, ensure_ascii=False))
            fallidos.append({"itemIdentifier": record["messageId"]})

    # Contrato de respuesta parcial: SQS solo reintenta los mensajes listados.
    return {"batchItemFailures": fallidos}


def _procesar_mensaje(record):
    """Valida el evento CITA_CREADA y registra la notificacion al paciente."""
    cuerpo = json.loads(record["body"])

    faltantes = [campo for campo in CAMPOS_OBLIGATORIOS if not cuerpo.get(campo)]
    if faltantes:
        raise ValueError(f"Mensaje invalido, faltan campos: {', '.join(faltantes)}")

    notificacion = (
        f"Estimado/a {cuerpo['nombrePaciente']} (RUT {cuerpo['rutPaciente']}): "
        f"su cita N.{cuerpo['idCita']} fue agendada para el {cuerpo['fechaHora']}. "
        f"Motivo: {cuerpo.get('motivo', 'no informado')}."
    )

    logger.info(json.dumps({
        "evento": "notificacion_enviada",
        "idCita": cuerpo["idCita"],
        "rutPaciente": cuerpo["rutPaciente"],
        "medicoId": cuerpo.get("medicoId"),
        "mensaje": notificacion,
    }, ensure_ascii=False))
