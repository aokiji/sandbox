from datetime import date, timedelta
import html
import subprocess
from calibracion.redmine import GestionTareas
from collections import defaultdict

from redminelib.resources import Issue

EMOJI_ESTADO_TAREA = {"Cerrada": "✅", "En curso": "🚧", "Rechazada": "✖️", "Nueva": "🆕"}


def obtener_tareas() -> list[Issue]:
    gestion_tareas = GestionTareas()
    redmine = gestion_tareas._redmine

    return redmine.issue.filter(query_id=2438)


def tareas_sprint_anterior(tareas: list[Issue]):
    tareas_por_proyecto = defaultdict(list)
    for tarea in tareas:
        if tarea.status.name == "Nueva":
            continue
        titulo_proyecto = tarea.project.name
        tareas_por_proyecto[titulo_proyecto].append(tarea)

    return tareas_por_proyecto


def tareas_sprint_siguiente(tareas: list[Issue]):
    tareas_por_proyecto = defaultdict(list)
    for tarea in tareas:
        if tarea.status.name not in ["Nueva", "En curso"]:
            continue
        titulo_proyecto = tarea.project.name
        tareas_por_proyecto[titulo_proyecto].append(tarea)

    return tareas_por_proyecto


def emojis_tarea(tarea: Issue) -> str:
    emojis = set()

    if tarea.status.name in EMOJI_ESTADO_TAREA:
        emojis.add(EMOJI_ESTADO_TAREA[tarea.status.name])

    if tarea.start_date + timedelta(days=28) > date.today():
        emojis.add(EMOJI_ESTADO_TAREA["Nueva"])

    return " ".join(emojis)


def generar_lista_html(tareas_por_proyecto: dict[str, list[Issue]]) -> str:
    html_output = "<ul>\n"
    for proyecto, tareas in sorted(tareas_por_proyecto.items()):
        html_output += f"  <li>{html.escape(proyecto)}\n    <ul>\n"
        for tarea in tareas:
            url_tarea = f"{GestionTareas.DEFAULT_REDMINE_URL}/issues/{tarea.id}"
            emojis = emojis_tarea(tarea)
            tarea_html = f'{emojis} {tarea.subject} <a href="{url_tarea}">#{tarea.id}</a>'
            html_output += f"      <li>{tarea_html}</li>\n"
        html_output += "    </ul>\n  </li>\n"
    return html_output


def generar_html(tareas: list[Issue]):
    today = date.today()
    tareas_por_proyecto = tareas_sprint_anterior(tareas)
    html_output = f"<h2>Sprint {today.strftime('%Y-%m')}</h2>"
    html_output += generar_lista_html(tareas_por_proyecto)
    next_sprint = today + timedelta(days=26)
    html_output += f"<h2>Sprint {next_sprint.strftime('%Y-%m')}</h2>"
    tareas_por_proyecto = tareas_sprint_siguiente(tareas)
    html_output += generar_lista_html(tareas_por_proyecto)
    html_output += "</ul>\n"
    return html_output


def copiar_a_xclip(html_text):
    proceso = subprocess.Popen(["xclip", "-selection", "clipboard", "-t", "text/html"], stdin=subprocess.PIPE)
    proceso.communicate(input=html_text.encode("utf-8"))


if __name__ == "__main__":
    tareas = obtener_tareas()
    html_texto = generar_html(tareas)
    copiar_a_xclip(html_texto)
    print("✅ Copiado al portapapeles como HTML (pega en Google Docs).")
