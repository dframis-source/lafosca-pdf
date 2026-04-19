import io, os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, HRFlowable, KeepTogether
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.platypus import Flowable
from PIL import Image as PILImage

TERRA   = colors.HexColor("#C8956B")
TERRA_D = colors.HexColor("#A67550")
TERRA_L = colors.HexColor("#F5EBE0")
DARK    = colors.HexColor("#2C1810")
MID     = colors.HexColor("#5C4035")
GREY    = colors.HexColor("#9A8880")
BORDER  = colors.HexColor("#E8D5C0")

def generate_pdf(NAME, IDIOMA, ESTIU, NOTES=""):
    # Auto salutation
    _low = NAME.lower()
    _familia = any(x in _low for x in ["famí","fami","family","familie"])
    _femeni = NAME.rstrip()[-1] == "a" and not _familia
    if IDIOMA == "catala":
        if _familia: SALUT = f"Hola, {NAME}, benvinguts a La Fosca!"
        elif _femeni: SALUT = f"Hola {NAME}, benvinguda a La Fosca!"
        else: SALUT = f"Hola {NAME}, benvingut a La Fosca!"
    elif IDIOMA == "castella":
        if _familia: SALUT = f"¡Hola, {NAME}, bienvenidos a La Fosca!"
        elif _femeni: SALUT = f"¡Hola {NAME}, bienvenida a La Fosca!"
        else: SALUT = f"¡Hola {NAME}, bienvenido a La Fosca!"
    elif IDIOMA == "angles":
        SALUT = f"Welcome to La Fosca, {NAME}!"
    else:
        if _familia: SALUT = f"Willkommen in La Fosca, {NAME}!"
        else: SALUT = f"Herzlich willkommen in La Fosca, {NAME}!"

    PAGE_W, PAGE_H = A4
    L_MAR = R_MAR = 2.0 * cm
    T_MAR = 1.4 * cm
    B_MAR = 2.0 * cm
    TW = PAGE_W - L_MAR - R_MAR

    HERO_PATH = os.path.join(os.path.dirname(__file__), "static", "cala_salguer.jpg")
    HERO_DST = "/tmp/lafosca_hero.jpg"

    if os.path.exists(HERO_PATH):
        img = PILImage.open(HERO_PATH).convert("RGB")
        tw, th = 1600, 560
        r = max(tw/img.width, th/img.height)
        nw, nh = int(img.width*r), int(img.height*r)
        img = img.resize((nw, nh), PILImage.LANCZOS)
        cx, cy = nw//2, nh//2
        img = img.crop((cx-tw//2, cy-th//2, cx+tw//2, cy+th//2))
        img.save(HERO_DST, "JPEG", quality=92)
        HAS_HERO = True
    else:
        HAS_HERO = False

    class HeroImage(Flowable):
        def __init__(self, path, width, height, caption=""):
            super().__init__()
            self.path = path; self.width = width; self.height = height; self.caption = caption
        def wrap(self, aw, ah): return self.width, self.height + (0.45*cm if self.caption else 0)
        def draw(self):
            c = self.canv
            c.drawImage(self.path, 0, 0.45*cm if self.caption else 0, width=self.width, height=self.height, preserveAspectRatio=False, mask="auto")
            if self.caption:
                c.setFont("Helvetica-Oblique", 7.5); c.setFillColor(GREY)
                c.drawRightString(self.width, 0.08*cm, self.caption)

    class SecHeader(Flowable):
        PAD = 0.35*cm
        def __init__(self, emoji, title, width=None):
            super().__init__()
            self.emoji = emoji; self.title = title; self.width = width or TW; self.height = 0.85*cm
        def wrap(self, aw, ah): return self.width, self.height + self.PAD
        def draw(self):
            c = self.canv; w = self.width
            c.setFillColor(TERRA_L); c.roundRect(0, 0, w, self.height, radius=4, fill=1, stroke=0)
            c.setFillColor(TERRA); c.rect(0, 0, 0.22*cm, self.height, fill=1, stroke=0)
            c.setFillColor(TERRA_D); c.setFont("Helvetica-Bold", 11)
            c.drawString(0.5*cm, 0.27*cm, f"{self.emoji}  {self.title.upper()}")

    class Div(Flowable):
        def __init__(self, width=None): super().__init__(); self.width = width or TW; self.height = 0.01*cm
        def wrap(self, aw, ah): return self.width, self.height + 0.15*cm
        def draw(self):
            c = self.canv; c.setStrokeColor(BORDER); c.setLineWidth(0.4)
            c.line(0.5*cm, 0, self.width-0.5*cm, 0)

    def ST(name, **kw): return ParagraphStyle(name, **kw)
    S = {
        "title":   ST("title", fontName="Helvetica-Bold", fontSize=21, textColor=TERRA_D, leading=26, spaceBefore=0.3*cm, spaceAfter=0.05*cm),
        "salut":   ST("salut", fontName="Helvetica-Bold", fontSize=13.5, textColor=TERRA, leading=18, spaceBefore=0, spaceAfter=0.05*cm),
        "sub":     ST("sub", fontName="Helvetica", fontSize=9.5, textColor=GREY, leading=13, spaceAfter=0.3*cm),
        "intro":   ST("intro", fontName="Helvetica", fontSize=10.2, textColor=MID, leading=15.5, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
        "wt":      ST("wt", fontName="Helvetica-Bold", fontSize=10, textColor=DARK, leading=14, spaceBefore=0.28*cm, spaceAfter=0.04*cm),
        "body":    ST("body", fontName="Helvetica", fontSize=9.7, textColor=MID, leading=14.5, spaceAfter=0.04*cm, alignment=TA_JUSTIFY),
        "rname":   ST("rname", fontName="Helvetica-Bold", fontSize=10.2, textColor=DARK, leading=14, spaceBefore=0.22*cm, spaceAfter=0.04*cm),
        "rbody":   ST("rbody", fontName="Helvetica", fontSize=9.6, textColor=MID, leading=14, spaceAfter=0.04*cm, alignment=TA_JUSTIFY),
        "link":    ST("link", fontName="Helvetica", fontSize=8.5, textColor=TERRA_D, leading=12, spaceAfter=0.02*cm),
        "note":    ST("note", fontName="Helvetica-Oblique", fontSize=9, textColor=GREY, leading=13, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
        "village": ST("village", fontName="Helvetica", fontSize=9.7, textColor=MID, leading=14.5, spaceAfter=0.14*cm),
        "footer":  ST("footer", fontName="Helvetica-Oblique", fontSize=9, textColor=GREY, alignment=TA_CENTER),
        "pb":      ST("pb", fontName="Helvetica", fontSize=9.6, textColor=MID, leading=14, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
    }

    def lnk(label, url):
        return Paragraph(f'<font color="#A67550">{label}:</font> <a href="{url}"><font color="#A67550">{url}</font></a>', S["link"])

    def rest_block(items):
        story = []
        for i, (name, loc, desc, links) in enumerate(items):
            block = []
            if i > 0: block.append(Div())
            loc_s = f' <font color="#9A8880" size="9">· {loc}</font>' if loc else ""
            block.append(Paragraph(f"{name}{loc_s}", S["rname"]))
            block.append(Paragraph(desc, S["rbody"]))
            for lbl, url in links: block.append(lnk(lbl, url))
            story.append(KeepTogether(block))
        return story

    OUT = "/tmp/lafosca_output.pdf"
    doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=L_MAR, rightMargin=R_MAR, topMargin=T_MAR, bottomMargin=B_MAR)
    frame = Frame(L_MAR, B_MAR, TW, PAGE_H-T_MAR-B_MAR, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="main")
    doc.addPageTemplates([PageTemplate(id="main", frames=[frame])])

    story = []

    if HAS_HERO:
        HERO_H = TW * (560/1600)
        story.append(HeroImage(HERO_DST, TW, HERO_H, caption="Cala S'Alguer · Palamós"))
        story.append(Spacer(1, 0.5*cm))

    story.append(Paragraph(NAME, S["title"]))
    story.append(Paragraph(SALUT, S["salut"]))
    story.append(Paragraph("La Fosca · Palamós · Costa Brava", S["sub"]))

    # Intro text by language
    intros = {
        "catala": "La Fosca és una de les zones més boniques i exclusives de Palamós: una cala preciosa, tranquil·la, una mica allunyada del bullici però a pocs minuts a peu de tot. Des de la platja podeu descobrir trams espectaculars del Camí de Ronda, un camí de costa que m'encanta i que us recomano moltíssim. Palamós és un poble amb molt d'encant, bon ambient i una gastronomia excel·lent, especialment per als amants del peix i el marisc.",
        "castella": "La Fosca es una de las zonas más bonitas y exclusivas de Palamós: una cala preciosa, tranquila, un poco alejada del bullicio pero a pocos minutos a pie de todo. Desde la playa podéis descubrir tramos espectaculares del Camí de Ronda, un camino de costa que me encanta y que os recomiendo muchísimo. Palamós es un pueblo con mucho encanto, buen ambiente y una gastronomía excelente.",
        "angles": "La Fosca is one of the most beautiful and exclusive areas of Palamós: a lovely quiet cove, slightly away from the town but just a short walk from everything. From the beach you can explore spectacular sections of the Camí de Ronda coastal path, which I love and highly recommend. Palamós is a charming town with wonderful atmosphere and excellent food.",
        "alemany": "La Fosca ist eine der schönsten und exklusivsten Gegenden von Palamós: eine wunderschöne, ruhige Bucht, etwas abseits vom Trubel, aber zu Fuß in wenigen Minuten von allem erreichbar. Vom Strand aus könnt ihr spektakuläre Abschnitte des Camí de Ronda entdecken, einen Køstenweg, den ich sehr liebe und sehr empfehle.",
    }
    story.append(Paragraph(intros.get(IDIOMA, intros["catala"]), S["intro"]))
    story.append(Spacer(1, 0.4*cm))

    # Section titles by language
    T = {
        "catala":   {"platges": "Platges de La Fosca", "passejos": "Passejos — Camí de Ronda", "bus": "Bus urbà La Fosca – Palamós", "rest_fosca": "Restaurants — La Fosca", "rest_pal": "Restaurants — Palamós", "compra": "On fer la compra", "aparc": "Aparcament a La Fosca", "pobles": "Pobles amb encant per visitar"},
        "castella":  {"platges": "Playas de La Fosca", "passejos": "Paseos — Camí de Ronda", "bus": "Bus urbano La Fosca – Palamós", "rest_fosca": "Restaurantes — La Fosca", "rest_pal": "Restaurantes — Palamós", "compra": "Dónde hacer la compra", "aparc": "Aparcamiento en La Fosca", "pobles": "Pueblos con encanto para visitar"},
        "angles":   {"platges": "Beaches of La Fosca", "passejos": "Walks — Camí de Ronda", "bus": "Local bus La Fosca – Palamós", "rest_fosca": "Restaurants — La Fosca", "rest_pal": "Restaurants — Palamós", "compra": "Food shopping", "aparc": "Parking at La Fosca", "pobles": "Charming villages to visit"},
        "alemany":  {"platges": "Strände von La Fosca", "passejos": "Spaziergänge — Camí de Ronda", "bus": "Stadtbus La Fosca – Palamós", "rest_fosca": "Restaurants — La Fosca", "rest_pal": "Restaurants — Palamós", "compra": "Einkaufen", "aparc": "Parken in La Fosca", "pobles": "Charmante Dörfer zum Besuchen"},
    }
    t = T.get(IDIOMA, T["catala"])

    # PLATGES
    story.append(KeepTogether([SecHeader("🏖️", t["platges"])]))
    story.append(Spacer(1, 0.18*cm))
    platja_data = {
        "catala": [("La Platja Petita", "Just a prop de casa, abans d'arribar a la platja gran. Hi ha pedres a l'entrada però un cop dins és fantàstica — tranquil·la, molt recollida, i pràcticament només hi van els locals. Molt recomanable."), ("La Platja de La Fosca", "La platja gran del barri, molt completa. Té la roca característica al centre — d'aquí ve el nom de La Fosca. Gran, amb bon ambient i serveis. Ideal per a famílies.")],
        "castella": [("La Playa Pequeña", "Justo cerca de casa, antes de llegar a la playa grande. Hay piedras en la entrada pero una vez dentro es fantástica — tranquila, muy recogida, y prácticamente solo van los locales. Muy recomendable."), ("La Playa de La Fosca", "La playa grande del barrio, muy completa. Tiene la roca característica en el centro — de ahí viene el nombre de La Fosca. Grande, con buen ambiente y servicios. Ideal para familias.")],
        "angles": [("The Small Beach", "Just near the apartment, before reaching the main beach. There are rocks at the entrance but once inside it's fantastic — quiet, sheltered, practically only visited by locals. Highly recommended."), ("La Fosca Beach", "The main beach of the area. It has the characteristic rock in the centre — which is how La Fosca got its name. Large, with good atmosphere and facilities. Ideal for families.")],
        "alemany": [("Der kleine Strand", "Direkt in der Nähe der Wohnung. Am Eingang gibt es Steine, aber drinnen ist es fantastisch — ruhig, geschützt und praktisch nur von Einheimischen besucht."), ("Strand von La Fosca", "Der Hauptstrand des Viertels. Er hat den charakteristischen Felsen in der Mitte — daher der Name La Fosca. Groß, mit guter Atmosphäre und Einrichtungen.")],
    }
    for i, (title, desc) in enumerate(platja_data.get(IDIOMA, platja_data["catala"])):
        block = []
        if i > 0: block.append(Div())
        block += [Paragraph(title, S["wt"]), Paragraph(desc, S["body"])]
        story.append(KeepTogether(block))
    story.append(Spacer(1, 0.45*cm))

    # PASSEJOS
    story.append(KeepTogether([SecHeader("🌿", t["passejos"])]))
    story.append(Spacer(1, 0.18*cm))
    walks_ca = [
        ("Anar a Palamós a peu ★ recomanat", "El camí més directe és seguir la carretera de La Fosca, passant pel Càmping Palamós — 15–20 min. No cal cotxe."),
        ("Camí de Ronda: La Fosca – Cala Margarida – Palamós", "Per la costa, passa per les casetes de Cala Margarida. Algunes pujades, molt bonic."),
        ("La Fosca – Cala S'Alguer – Platja del Castell – Cala Estreta", "Un passeig que m'encanta. Còmode fins a Platja del Castell. Després terreny canvia: pujades, baixades, arrels. Continua fins Calella/Llafranc."),
        ("Sant Antoni de Calonge – Platja d'Aro", "S'hi arriba caminant des de casa. Des d'allà Camí de Ronda fins Platja d'Aro, moltes cales amagades."),
        ("Platja d'Aro – S'Agaró", "Molt fàcil i planer, vistes espectaculars."),
        ("Calella de Palafrugell & Llafranc", "Curt Camí de Ronda que les connecta. Dos pobles plens d'encant."),
        ("Ruta del Tren Petit 🚲", "Via verda fins a Palafrugell. Per tornar, autobús fins a Palamós."),
    ]
    for title, desc in walks_ca:
        story.append(KeepTogether([Paragraph(title, S["wt"]), Paragraph(desc, S["body"])]))
    story.append(Spacer(1, 0.45*cm))

    # BUS (only summer)
    if ESTIU:
        story.append(KeepTogether([SecHeader("🚌", t["bus"])]))
        story.append(Spacer(1, 0.18*cm))
        bus_texts = {
            "catala": "Bus urbà Moventis SARFA, línia L2. Parada al Càmping Palamós / Cala Margarida. Horaris: visitpalamos.cat/documentacio-turistica",
            "castella": "Bus urbano Moventis SARFA, línea L2. Parada en Càmping Palamós / Cala Margarida. Horarios: visitpalamos.cat/documentacio-turistica",
            "angles": "Local bus Moventis SARFA, line L2. Stop at Càmping Palamós / Cala Margarida. Timetables: visitpalamos.cat/documentacio-turistica",
            "alemany": "Stadtbus Moventis SARFA, Linie L2. Haltestelle beim Càmping Palamós / Cala Margarida. Fahrplan: visitpalamos.cat/documentacio-turistica",
        }
        story.append(Paragraph(bus_texts.get(IDIOMA, bus_texts["catala"]), S["body"]))
        story.append(Spacer(1, 0.45*cm))

    # RESTAURANTS LA FOSCA
    story.append(KeepTogether([SecHeader("🍽️", t["rest_fosca"])]))
    story.append(Spacer(1, 0.18*cm))
    xiri_desc = {"catala": "Just a la platja, terrassa exterior. Truita, amanida russa, entepà de calamars, musclos. Perfecte per dinar informal.", "castella": "En la playa, terraza exterior. Tortilla, ensaladilla, bocadillo de calamares, mejillones.", "angles": "Right on the beach, outdoor terrace. Simple and very good food: omelette, Russian salad, calamari sandwich, mussels.", "alemany": "Direkt am Strand. Einfaches und sehr gutes Essen: Tortilla, Russischer Salat, Tintenfisch-Sandwich, Muscheln."}
    waves_desc = {"catala": "Sopar a La Fosca quan no es vol sortir del barri. Agradable.", "castella": "Cenar en La Fosca cuando no queréis alejaros. Agradable.", "angles": "Good dinner option in La Fosca when you don't want to go far. Pleasant.", "alemany": "Gute Abendessen-Option in La Fosca. Angenehm."}
    for b in rest_block([
        ("Xiringuito de Can Blau", "La Fosca", xiri_desc.get(IDIOMA, xiri_desc["catala"]), [("📍", "https://g.co/kgs/qcuJzdf")]),
        ("Waves", "La Fosca", waves_desc.get(IDIOMA, waves_desc["catala"]), [("📍", "https://g.co/kgs/4hFnUSk")]),
    ]): story.append(b)
    story.append(Spacer(1, 0.45*cm))

    # RESTAURANTS PALAMOS
    story.append(KeepTogether([SecHeader("🍽️", t["rest_pal"])]))
    story.append(Spacer(1, 0.18*cm))
    isaac_desc = {"catala": "Cuina de mercat en una masia del s.XVIII. Menú migdia entre setmana 22€, molt bona relació qualitat-preu. Cal cotxe, val moltíssim.", "castella": "Cocina de mercado en masía del s.XVIII. Menú mediodía entre semana 22€. Hay que ir en coche, vale muchísimo.", "angles": "Market cuisine in an 18th-century farmhouse. Weekday lunch menu 22€. You need a car, but absolutely worth it.", "alemany": "Marktküche in einem Bauernhof aus dem 18. Jahrhundert. Mittagsmenü unter der Woche 22€. Mit Auto, aber sehr empfehlenswert."}
    for b in rest_block([
        ("Sala de L'Isaac", "Llofriu", isaac_desc.get(IDIOMA, isaac_desc["catala"]), [("📋", "https://www.salagran.com/salaisaac/la-carta/"), ("📍", "https://g.co/kgs/SmXVEuY")]),
        ("Restaurant Nàutic", "Palamós", "Vistes al mar, arrossos al migdia. Reservar." if IDIOMA=="catala" else "Sea views, rice dishes. Book ahead.", [("📍", "https://g.co/kgs/X6GFeBf")]),
        ("Can Quel", "Palamós", "Menú entre setmana 21€, caps de setmana 30€. Reservar." if IDIOMA=="catala" else "Weekday menu 21€, weekend 30€. Book ahead.", [("🌍", "https://restaurantcanquelpalamos.com/"), ("📍", "https://g.co/kgs/QX5QpQG")]),
        ("Hotel Trias", "Palamós", "Bon menú diari davant del mar." if IDIOMA=="catala" else "Good daily menu by the sea.", [("🌍", "https://www.hoteltrias.com/restaurante.html")]),
        ("Bitàcora", "Palamós", "Platets per compartir, nous cada temporada. Preus raonables. Sense reserves, t'avisen quan hi ha taula." if IDIOMA=="catala" else "Small sharing dishes. No reservations, they call you when a table is free.", []),
        ("Txoko Donostiarra", "Palamós", "Només vespre, sense reserves. Sidra + pintxos calents que van sortint. Deixeu-vos portar." if IDIOMA=="catala" else "Evenings only, no reservations. Cider + hot pintxos from the kitchen. Go with the flow.", [("📍", "https://g.co/kgs/1Htn7D")]),
        ("Can Blau", "Palamós", "Peix i arrossos de primera. No és barat però val la pena." if IDIOMA=="catala" else "Excellent fish and rice. Not cheap but worth it.", [("📍", "https://maps.app.goo.gl/A8Pb68BSdD5dFofh8")]),
    ]): story.append(b)
    story.append(Spacer(1, 0.45*cm))

    # COMPRA
    story.append(KeepTogether([SecHeader("🛒", t["compra"])]))
    story.append(Spacer(1, 0.18*cm))
    compra_items = []
    if ESTIU:
        compra_items += [
            ("Spar", "La Fosca", "Supermercat de La Fosca. Obre tot el dia a l'estiu." if IDIOMA=="catala" else "Local supermarket. Open all day in summer.", [("📍", "https://www.google.com/maps/place/Spar+La+Fosca/@41.8601561,3.1458594,17z")]),
            ("La Fleca de l'Empordà", "La Fosca", "Forn davant del Spar. Pa i brioixeria. Obre al matí." if IDIOMA=="catala" else "Bakery opposite Spar. Bread and pastries. Open mornings.", [("🌐", "https://www.lafleca.com/ca/botigues/palamos-la-fosca/")]),
        ]
    compra_items += [
        ("Rotllan", "Palamós", "Fruiteria de tota la vida, molt bona qualitat." if IDIOMA=="catala" else "Traditional grocer, excellent quality.", [("📍", "https://g.co/kgs/XQuBbLf")]),
        ("Mercadona", "Palamós", "Cal cotxe, molt aparcament gratuït, preus bons." if IDIOMA=="catala" else "Car needed, free parking, good prices.", []),
        ("Bon Preu", "Palamós", "A l'entrada de La Fosca des de Palamós. Pràctic." if IDIOMA=="catala" else "At the entrance to La Fosca from Palamós. Convenient.", []),
    ]
    for b in rest_block(compra_items): story.append(b)
    story.append(Spacer(1, 0.45*cm))

    # APARCAMENT
    story.append(KeepTogether([SecHeader("🚗", t["aparc"])]))
    story.append(Spacer(1, 0.18*cm))
    if ESTIU:
        aparc_texts = {
            "catala": ["El camí de terra de l'apartament té aparcament gratuït. Normalment trobareu lloc a primera hora o a partir de mitja tarda.", "Si el camí és ple, deixeu el cotxe a la intersecció Camí de l'Església / carretera de La Fosca. Pagament fins que marxi la gent del dia."],
            "castella": ["El camino de tierra tiene aparcamiento gratuito. Normalmente encontraréis sitio a primera hora o desde media tarde.", "Si está lleno, dejad el coche en la intersección Camí de l'Església / carretera de La Fosca."],
            "angles": ["The dirt track has free parking. You can usually find a spot early morning or from mid-afternoon.", "If full, park at the junction of Camí de l'Església and the La Fosca road."],
            "alemany": ["Der Schotterweg hat kostenlosen Parkplatz. Früh morgens oder ab Mitte Nachmittag findet man meist einen Platz.", "Wenn voll, beim Kreuzung Camí de l'Església / Straße La Fosca parken."],
        }
        for p in aparc_texts.get(IDIOMA, aparc_texts["catala"]):
            story.append(Paragraph(p, S["pb"]))
        warn = {"catala": "⚠️  Zona regulada del 15 de juny al 15 de setembre.", "castella": "⚠️  Zona regulada del 15 de junio al 15 de septiembre.", "angles": "⚠️  Regulated parking zone from 15 June to 15 September.", "alemany": "⚠️  Regulierte Parkzone vom 15. Juni bis 15. September."}
        story.append(Paragraph(warn.get(IDIOMA, warn["catala"]), S["note"]))
    else:
        noestu = {"catala": "Fora dels mesos d'estiu no hi ha cap problema per aparcar al camí de terra de l'apartament, sense restriccions.", "castella": "Fuera de los meses de verano no hay ningún problema para aparcar en el camino de tierra, sin restricciones.", "angles": "Outside summer months there are no parking restrictions. You can park freely on the dirt track next to the apartment.", "alemany": "Außerhalb der Sommermonate gibt es keine Parkbeschränkungen auf dem Schotterweg neben der Wohnung."}
        story.append(Paragraph(noestu.get(IDIOMA, noestu["catala"]), S["pb"]))
    story.append(Spacer(1, 0.45*cm))

    # POBLES
    story.append(KeepTogether([SecHeader("🏡", t["pobles"])]))
    story.append(Spacer(1, 0.18*cm))
    pobles_intro = {"catala": "Amb cotxe, aquests pobles valen molt la pena. A l'estiu, aparcament complicat als pobles de costa — millor anar-hi de matí o a la tarda.", "castella": "Con coche, estos pueblos valen mucho la pena. En verano, aparcamiento complicado — mejor ir de mañana o tarde.", "angles": "With a car, these nearby villages are well worth a visit. In summer, parking can be tricky — go early or in the afternoon.", "alemany": "Mit Auto sehr empfehlenswert. Im Sommer kann das Parken schwierig sein — früh morgens oder am Nachmittag fahren."}
    story.append(Paragraph(pobles_intro.get(IDIOMA, pobles_intro["catala"]), S["body"]))
    story.append(Spacer(1, 0.15*cm))
    pobles = [("Calella de Palafrugell – Llafranc", "12 km", "Units per Camí de Ronda preciós. Dels més bonics Costa Brava."), ("Tamariu", "17 km", "Cala petita i íntima, poc massificada. Secret ben guardat."), ("Begur", "17 km", "Medieval amb castell i vistes impressionants."), ("Pals", "20 km", "Nucli medieval ben conservat. Molt fotogènic."), ("Peratallada", "22 km", "Dels més bonics de Catalunya. Combina amb Pals."), ("Platja d'Aro", "13 km", "Passeig marítim i carrer comercial. Cinema (ocineplatjadaro.es).")]
    for nom, dist, desc in pobles:
        story.append(KeepTogether([Paragraph(f'<b>{nom}</b>  <font color="#9A8880" size="9">({dist})</font><br/><font size="9.3" color="#5C4035">{desc}</font>', S["village"])]))

    if NOTES:
        story.append(Spacer(1, 0.4*cm))
        story.append(KeepTogether([SecHeader("📝", "Notes")]))
        story.append(Spacer(1, 0.18*cm))
        story.append(Paragraph(NOTES, S["body"]))

    footers = {"catala": "Qualsevol dubte, estic a la vostra disposició. Bon descans i gaudiu de La Fosca! 🌊", "castella": "Cualquier duda, estoy a vuestra disposición. ¡Buen descanso y disfrutad de La Fosca! 🌊", "angles": "Any questions, I'm at your disposal. Enjoy your stay at La Fosca! 🌊", "alemany": "Bei Fragen stehe ich euch gerne zur Verfügung. Genießt La Fosca! 🌊"}
    story.append(Spacer(1, 0.6*cm))
    story.append(HRFlowable(width=TW, thickness=0.6, color=BORDER, spaceAfter=0.2*cm))
    story.append(Paragraph(footers.get(IDIOMA, footers["catala"]), S["footer"]))

    doc.build(story)
    with open(OUT, "rb") as f:
        return f.read()
