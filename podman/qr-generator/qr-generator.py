import argparse
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.utils import ImageReader
import qrcode
import io
import os
from ulid import ULID

parser = argparse.ArgumentParser(description="Generate QR labels PDF")
parser.add_argument(
    "--base-url",
    default=None,
    help="Base URL for generated tags (or set BASE_URL env var)",
)
parser.add_argument(
    "--output-dir",
    default=None,
    help="Output directory for generated PDF (or set OUTPUT_DIR env var)",
)
parser.add_argument(
    "--pages",
    type=int,
    default=1,
    help="Number of pages to generate (default: 1)",
)
args = parser.parse_args()
BASE_URL = (args.base_url or os.getenv("BASE_URL"))
OUTPUT_DIR = (args.output_dir or os.getenv("OUTPUT_DIR"))
PAGES = args.pages

if not BASE_URL:
    parser.error("Missing required base URL. Use --base-url or set BASE_URL.")
if not OUTPUT_DIR:
    parser.error("Missing required output directory. Use --output-dir or set OUTPUT_DIR.")
if PAGES < 1:
    parser.error("--pages must be greater than or equal to 1.")

BASE_URL = BASE_URL.rstrip("/")
OUTPUT_PDF = os.path.join(
    OUTPUT_DIR,
    f"music-qr-codes-{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.pdf",
)

output_dir = os.path.dirname(OUTPUT_PDF)
if output_dir:
    os.makedirs(output_dir, exist_ok=True)

# Configuración de etiquetas optimizada
MARGIN_X = 8 * mm
MARGIN_Y = 8 * mm
# Sin separacion horizontal entre etiquetas: el espacio queda en los margenes laterales.
LABEL_GAP_X = 0 * mm
LABEL_GAP_Y = 0.5 * mm
QR_INNER_PADDING = 3 * mm
ROWS = 6
CROP_MARK_LENGTH = 4 * mm  # Reducido de 5mm
CROP_MARK_LINE_WIDTH = 0.45  # Apenas mas gruesa para mejor visibilidad

PAGE_WIDTH, PAGE_HEIGHT = A4
COLS = 4
LABEL_WIDTH = (PAGE_WIDTH - 2 * MARGIN_X - (COLS - 1) * LABEL_GAP_X) / COLS
LABEL_HEIGHT = (PAGE_HEIGHT - 2 * MARGIN_Y - (ROWS - 1) * LABEL_GAP_Y) / ROWS
QR_SIZE = min(
    LABEL_WIDTH - 2 * QR_INNER_PADDING,
    LABEL_HEIGHT - 2 * QR_INNER_PADDING,
)
LABELS_PER_PAGE = COLS * ROWS
TOTAL_LABELS = LABELS_PER_PAGE * PAGES


def draw_crop_crosses_grid(canvas_obj):
    canvas_obj.setStrokeColor(colors.black)
    canvas_obj.setLineWidth(CROP_MARK_LINE_WIDTH)

    half_len = CROP_MARK_LENGTH / 2

    # Limites reales de la grilla de etiquetas.
    grid_left = MARGIN_X
    grid_right = PAGE_WIDTH - MARGIN_X
    grid_top = PAGE_HEIGHT - MARGIN_Y
    grid_bottom = grid_top - ROWS * LABEL_HEIGHT - (ROWS - 1) * LABEL_GAP_Y

    # Cortes internos reales entre columnas y filas de etiquetas.
    internal_x = [
        grid_left + col * LABEL_WIDTH + (col - 0.5) * LABEL_GAP_X
        for col in range(1, COLS)
    ]
    internal_y = [
        grid_top - row * LABEL_HEIGHT - (row - 0.5) * LABEL_GAP_Y
        for row in range(1, ROWS)
    ]

    # Cruces en el centro de 4 QR (intersecciones internas).
    for cross_x in internal_x:
        for cross_y in internal_y:
            canvas_obj.line(cross_x - half_len, cross_y, cross_x + half_len, cross_y)
            canvas_obj.line(cross_x, cross_y - half_len, cross_x, cross_y + half_len)

    # Cruces en bordes superior e inferior de la grilla para cortes verticales internos.
    for cross_x in internal_x:
        canvas_obj.line(cross_x - half_len, grid_top, cross_x + half_len, grid_top)
        canvas_obj.line(cross_x, grid_top - half_len, cross_x, grid_top + half_len)
        canvas_obj.line(cross_x - half_len, grid_bottom, cross_x + half_len, grid_bottom)
        canvas_obj.line(cross_x, grid_bottom - half_len, cross_x, grid_bottom + half_len)

    # Cruces en bordes izquierdo y derecho de la grilla para cortes horizontales internos.
    for cross_y in internal_y:
        canvas_obj.line(grid_left - half_len, cross_y, grid_left + half_len, cross_y)
        canvas_obj.line(grid_left, cross_y - half_len, grid_left, cross_y + half_len)
        canvas_obj.line(grid_right - half_len, cross_y, grid_right + half_len, cross_y)
        canvas_obj.line(grid_right, cross_y - half_len, grid_right, cross_y + half_len)

    # Cruces en las 4 esquinas (cortes exteriores).
    for cross_x, cross_y in [
        (grid_left, grid_top),
        (grid_right, grid_top),
        (grid_left, grid_bottom),
        (grid_right, grid_bottom),
    ]:
        canvas_obj.line(cross_x - half_len, cross_y, cross_x + half_len, cross_y)
        canvas_obj.line(cross_x, cross_y - half_len, cross_x, cross_y + half_len)


c = canvas.Canvas(OUTPUT_PDF, pagesize=A4)
y_start = PAGE_HEIGHT - MARGIN_Y - LABEL_HEIGHT

x_start = MARGIN_X

x = x_start
y = y_start

draw_marks_this_page = True

for _ in range(TOTAL_LABELS):
    tag_id = str(ULID())
    url = f"{BASE_URL}/{tag_id}"

    # Generar QR en memoria
    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_Q,
        box_size=10,
        border=1,
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")

    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)

    if draw_marks_this_page:
        draw_crop_crosses_grid(c)
        draw_marks_this_page = False

    # QR centrado en la etiqueta
    qr_x = x + (LABEL_WIDTH - QR_SIZE) / 2
    qr_y = y + (LABEL_HEIGHT - QR_SIZE) / 2
    c.drawImage(
        ImageReader(buffer),
        qr_x,
        qr_y,
        QR_SIZE,
        QR_SIZE
    )

    # Agregar icono PNG en el centro del QR
    # Tamaño del icono: 35% del QR (límite máximo recomendado)
    icon_size = QR_SIZE * 0.35

    # Posición centrada en el QR
    icon_x = qr_x + (QR_SIZE - icon_size) / 2
    icon_y = qr_y + (QR_SIZE - icon_size) / 2

    # Dibujar círculo blanco de fondo para que el icono resalte
    c.setFillColor(colors.white)
    c.setStrokeColor(colors.white)
    circle_radius = icon_size / 2
    c.circle(icon_x + circle_radius, icon_y + circle_radius, circle_radius * 1.1, stroke=1, fill=1)

    # Renderizar el PNG del vinilo
    c.drawImage(
        "Vinyl_record.png",
        icon_x,
        icon_y,
        icon_size,
        icon_size,
        mask='auto'  # Transparencia automática
    )


    # Avanzar posición
    x += LABEL_WIDTH + LABEL_GAP_X
    if x + LABEL_WIDTH > PAGE_WIDTH - MARGIN_X:
        x = x_start
        y -= LABEL_HEIGHT + LABEL_GAP_Y
        if y < MARGIN_Y:
            c.showPage()
            y = y_start
            draw_marks_this_page = True

c.save()
print(f"PDF generado: {OUTPUT_PDF}")