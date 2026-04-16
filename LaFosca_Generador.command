#!/bin/bash
# ═══════════════════════════════════════════════
#  La Fosca · Generador de recomanacions
#  Fes doble clic per generar un PDF personalitzat
# ═══════════════════════════════════════════════

clear
echo "╔══════════════════════════════════════════╗"
echo "║   La Fosca · Generador de recomanacions  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Dades d'entrada ──────────────────────────────
read -p "👤 Nom (ex: Família García): " NOM
read -p "👋 Salutació (ex: Hola Anna i Marc!): " SALUT
echo ""
echo "🌍 Idioma:"
echo "  1) Català"
echo "  2) Castellà"
echo "  3) Anglès"
echo "  4) Alemany"
read -p "   Tria (1-4): " IDIOMA_NUM
echo ""
echo "☀️  Estiu (juliol-agost)?"
echo "  1) Sí"
echo "  2) No"
read -p "   Tria (1-2): " ESTIU_NUM
echo ""
read -p "📝 Notes especials (o deixa buit): " NOTES
echo ""

# ── Convertir opcions ─────────────────────────────
case $IDIOMA_NUM in
  1) IDIOMA="catala" ;;
  2) IDIOMA="castella" ;;
  3) IDIOMA="angles" ;;
  4) IDIOMA="alemany" ;;
  *) IDIOMA="catala" ;;
esac

if [ "$ESTIU_NUM" = "1" ]; then
  ESTIU="True"
else
  ESTIU="False"
fi

DESKTOP="$HOME/Desktop"
OUTPUT="$DESKTOP/LaFosca_${NOM// /_}.pdf"
HERO_SRC="$(dirname "$0")/cala_salguer.jpg"
HERO_DST="/tmp/lafosca_hero.jpg"

echo "⏳ Generant el PDF..."
echo ""

# ── Instal·lar dependències si cal ────────────────
python3 -c "import reportlab, PIL" 2>/dev/null || {
  echo "📦 Instal·lant dependències (primera vegada)..."
  pip3 install reportlab Pillow --quiet
}

# ── Generar PDF ───────────────────────────────────
python3 << PYEOF
import sys, os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, HRFlowable, KeepTogether
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.platypus import Flowable
from PIL import Image as PILImage

NAME   = """$NOM"""
SALUT  = """$SALUT"""
ESTIU  = $ESTIU
IDIOMA = "$IDIOMA"
NOTES  = """$NOTES"""
OUT    = """$OUTPUT"""
HERO_SRC = """$HERO_SRC"""
HERO_DST = """$HERO_DST"""

# ── Colors ────────────────────────────────────────
TERRA   = colors.HexColor("#C8956B")
TERRA_D = colors.HexColor("#A67550")
TERRA_L = colors.HexColor("#F5EBE0")
DARK    = colors.HexColor("#2C1810")
MID     = colors.HexColor("#5C4035")
GREY    = colors.HexColor("#9A8880")
BORDER  = colors.HexColor("#E8D5C0")

PAGE_W, PAGE_H = A4
L_MAR = R_MAR = 2.0 * cm
T_MAR = 1.4 * cm
B_MAR = 2.0 * cm
TW = PAGE_W - L_MAR - R_MAR

# ── Preparar hero ─────────────────────────────────
if os.path.exists(HERO_SRC):
    img = PILImage.open(HERO_SRC).convert("RGB")
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

# ── Traduccions ───────────────────────────────────
T = {}
if IDIOMA == "catala":
    T = {
        "intro": f"La Fosca és una de les zones més boniques i exclusives de Palamós: una cala preciosa, tranquil·la, una mica allunyada del bullici però a pocs minuts a peu de tot. Des de la platja podeu descobrir trams espectaculars del Camí de Ronda, un camí de costa que m'encanta i que us recomano moltíssim. Palamós és un poble amb molt d'encant, bon ambient i una gastronomia excel·lent, especialment per als amants del peix i el marisc.",
        "sub": "La Fosca · Palamós · Costa Brava",
        "platges_tit": "Platges de La Fosca",
        "p1_nom": "La Platja Petita", "p1_desc": "Just a prop de casa, abans d'arribar a la platja gran. Hi ha pedres a l'entrada però un cop dins és fantàstica — tranquil·la, molt recollida, i pràcticament només hi van els locals. Molt recomanable.",
        "p2_nom": "La Platja de La Fosca", "p2_desc": "La platja gran del barri, molt completa. Té la roca característica al centre — d'aquí ve el nom de La Fosca. És gran, amb bon ambient i serveis. Ideal per a famílies.",
        "passejos_tit": "Passejos — Camí de Ronda",
        "w1_nom": "Anar a Palamós a peu  ★ recomanat", "w1_desc": "El camí més directe és seguir la carretera de La Fosca, passant per davant del Càmping Palamós — uns 15–20 minuts caminant. No cal agafar el cotxe: Palamós és un poble petit i molt agradable de recórrer a peu.",
        "w2_nom": "Camí de Ronda: La Fosca – Cala Margarida – Palamós", "w2_desc": "Si voleu arribar a Palamós passejant per la costa, podeu fer aquest petit tram que surt de La Fosca i passa per les casetes de Cala Margarida. Té algunes pujades, però és molt bonic. Una bona excusa per no anar amb pressa.",
        "w3_nom": "La Fosca – Cala S'Alguer – Platja del Castell – Cala Canyers – Cala Corbs – Cala Estreta", "w3_desc": "Un passeig que m'encanta. Comença just al final de la platja de La Fosca. Fins a Platja del Castell el camí és còmode i apte per a tothom. A partir d'aquí el terreny canvia: pujades, baixades, arrels, troncs. El camí continua fins a Calella de Palafrugell i Llafranc, però fer-ho tot i tornar és per a grans caminadors.",
        "w4_nom": "Sant Antoni de Calonge – Platja d'Aro", "w4_desc": "Sant Antoni és la continuació natural de Palamós, units pel passeig marítim — s'hi pot arribar caminant des de casa. Des d'allà, el Camí de Ronda fins a Platja d'Aro és un passeig preciós passant per moltes cales amagades.",
        "w5_nom": "Platja d'Aro – S'Agaró", "w5_desc": "Un passeig molt fàcil i planer, amb vistes espectaculars.",
        "w6_nom": "Calella de Palafrugell & Llafranc", "w6_desc": "Visiteu Calella i feu el curt Camí de Ronda que la connecta amb Llafranc. Dos pobles petits i plens d'encant, perfectes per passejar i sopar.",
        "w7_nom": "Ruta del Tren Petit 🚲", "w7_desc": "Aquesta antiga via de tren s'ha convertit en una via verda ideal per caminar, córrer o anar en bici fins a Palafrugell. Per tornar, podeu agafar l'autobús des de l'estació de Palafrugell fins a Palamós 🚌.",
        "bus_tit": "Bus urbà La Fosca – Palamós", "bus_desc": "A l'estiu (finals de juny a principis de setembre) hi ha el bus urbà de Moventis SARFA, línia L2, que connecta La Fosca amb el centre de Palamós. La parada és al Càmping Palamós / Cala Margarida. Horaris a: visitpalamos.cat/documentacio-turistica",
        "rest_fosca_tit": "Restaurants — La Fosca",
        "rest_pal_tit": "Restaurants — Palamós",
        "compra_tit": "On fer la compra",
        "aparc_tit": "Aparcament a La Fosca",
        "aparc_estiu1": "El camí de terra de l'apartament té aparcament gratuït. Normalment podeu trobar lloc sense problema a primera hora del matí o a partir de mitja tarda, quan ja ha marxat la gent que ve a passar el dia. Jo sempre aparco allà.",
        "aparc_estiu2": "Si quan arribeu el camí és ple, la millor opció és deixar el cotxe a la intersecció entre el Camí de l'Església de La Fosca i la carretera de La Fosca. Hi ha aparcament de pagament, però a partir de la tarda podreu passar al camí de terra gratuït.",
        "aparc_estiu3": "⚠️  La zona d'aparcament regulat de La Fosca (zona vermella i blava) només està habilitada del 15 de juny al 15 de setembre.",
        "aparc_noestu": "Fora dels mesos d'estiu no hi ha cap problema per aparcar. Podeu deixar el cotxe tranquil·lament al carrer on és l'apartament, al camí de terra, sense restriccions.",
        "pobles_tit": "Pobles amb encant per visitar",
        "pobles_intro": "Si teniu temps i cotxe, aquests pobles de la zona valen molt la pena. A l'estiu l'aparcament als pobles de costa pot ser complicat — millor anar-hi a primera hora o a la tarda.",
        "footer": "Qualsevol dubte, estic a la vostra disposició. Bon descans i gaudiu de La Fosca! 🌊",
        "spar_desc": "El supermercat de La Fosca, molt pràctic si tornes de les cales o de la platja. A l'estiu obre tot el dia.",
        "fleca_desc": "El forn, just davant del Spar. Pa i brioixeria de qualitat. A l'estiu obre al matí.",
        "rotllan_desc": "Una fruiteria de tota la vida amb producte de molt bona qualitat. Una mica cara, però s'hi nota la diferència.",
        "mercadona_desc": "Cal anar-hi en cotxe, però té molt d'aparcament gratuït i els preus són bons. La millor opció per fer la compra gran de la setmana.",
        "bonpreu_desc": "A l'entrada de La Fosca des de Palamós. Molt pràctic si us falta alguna cosa i heu vingut passejant.",
        "isaac_desc": "Un lloc especial. Cuina de mercat amb molt de producte local, dins d'una masia del segle XVIII. El menú de migdia entre setmana és una molt bona relació qualitat-preu: 22€. A l'hora de dinar també podeu triar altres menús de gamma superior, i a partir del vespre funcionen amb carta. Cal anar-hi amb cotxe, però val moltíssim la pena.",
        "nautic_desc": "Restaurant amb vistes al mar, ideal per a un dinar tranquil. Especialistes en arrossos al migdia. Es recomana reservar.",
        "canquel_desc": "Molt bon menú entre setmana per 21€, amb paella i plat de temporada. Els caps de setmana, menú especial a 30€. Val la pena reservar.",
        "trias_desc": "Bon menú diari en un entorn elegant davant del mar. Consulteu el preu actual a la seva web.",
        "bitacora_desc": "Un racó que m'ha conquistat. Hi vaig de nit a sopar i sempre hi ha ambient i molta gent. Els platets — petits, per compartir — no paren de sorprendre. Preus molt raonables. No accepten reserves però t'agafen el número i t'avisen quan hi hagi taula.",
        "txoko_desc": "Només obren al vespre i no accepten reserves. Demaneu una ampolla de sidra i espereu que vagin passant amb les safates: pintxos calents que surten de cuina sense parar. Deixeu-vos portar.",
        "canblau_desc": "Molt bon restaurant de peix i arrossos. No és dels més econòmics, però el producte és de primera i val la pena.",
        "xiringuito_desc": "Just a la platja, amb terrassa exterior. Menjar senzill i molt bo: truita de patates, amanida russa, entrepà de calamars, musclos... Perfecte per a un dinar informal.",
        "waves_desc": "Bona opció per sopar a La Fosca quan no us voleu moure del barri. Agradable.",
        "calella_desc": "Units per un Camí de Ronda preciós. Dos dels pobles més bonics de la Costa Brava.",
        "tamariu_desc": "Cala petita i íntima, poc massificada. Un dels secrets millor guardats de la zona.",
        "begur_desc": "Poble medieval amb castell i vistes impressionants. Molt recomanable.",
        "pals_desc": "Nucli medieval molt ben conservat al mig de l'Empordà. Molt fotogènic.",
        "peratallada_desc": "Un dels pobles medievals més bonics de Catalunya. Es pot combinar perfectament amb Pals.",
        "platjadaro_desc": "Té un bon passeig marítim i carrer comercial. Al centre comercial és fàcil aparcar i hi ha cinema (ocineplatjadaro.es).",
    }
elif IDIOMA == "castella":
    T = {
        "intro": f"La Fosca es una de las zonas más bonitas y exclusivas de Palamós: una cala preciosa, tranquila, un poco alejada del bullicio pero a pocos minutos a pie de todo. Desde la playa podéis descubrir tramos espectaculares del Camí de Ronda, un camino de costa que me encanta y que os recomiendo muchísimo. Palamós es un pueblo con mucho encanto, buen ambiente y una gastronomía excelente, especialmente para los amantes del pescado y el marisco.",
        "sub": "La Fosca · Palamós · Costa Brava",
        "platges_tit": "Playas de La Fosca",
        "p1_nom": "La Playa Pequeña", "p1_desc": "Justo cerca de casa, antes de llegar a la playa grande. Hay piedras en la entrada pero una vez dentro es fantástica — tranquila, muy recogida, y prácticamente solo van los locales. Muy recomendable.",
        "p2_nom": "La Playa de La Fosca", "p2_desc": "La playa grande del barrio, muy completa. Tiene la roca característica en el centro — de ahí viene el nombre de La Fosca. Es grande, con buen ambiente y servicios. Ideal para familias.",
        "passejos_tit": "Paseos — Camí de Ronda",
        "w1_nom": "Ir a Palamós a pie  ★ recomendado", "w1_desc": "El camino más directo es seguir la carretera de La Fosca, pasando por delante del Càmping Palamós — unos 15–20 minutos caminando. No hace falta coger el coche: Palamós es un pueblo pequeño y muy agradable de recorrer a pie.",
        "w2_nom": "Camí de Ronda: La Fosca – Cala Margarida – Palamós", "w2_desc": "Si queréis llegar a Palamós paseando por la costa, podéis hacer este pequeño tramo que sale de La Fosca y pasa por las casitas de Cala Margarida. Tiene algunas subidas, pero es muy bonito.",
        "w3_nom": "La Fosca – Cala S'Alguer – Platja del Castell – Cala Canyers – Cala Corbs – Cala Estreta", "w3_desc": "Un paseo que me encanta. Empieza justo al final de la playa de La Fosca. Hasta Platja del Castell el camino es cómodo y apto para todos. A partir de ahí el terreno cambia: subidas, bajadas, raíces. El camino continúa hasta Calella de Palafrugell y Llafranc, pero hacerlo todo y volver es para grandes caminadores.",
        "w4_nom": "Sant Antoni de Calonge – Platja d'Aro", "w4_desc": "Sant Antoni es la continuación natural de Palamós, unidos por el paseo marítimo — se puede llegar caminando desde casa. Desde allí, el Camí de Ronda hasta Platja d'Aro es un precioso paseo pasando por muchas calas escondidas.",
        "w5_nom": "Platja d'Aro – S'Agaró", "w5_desc": "Un paseo muy fácil y llano, con vistas espectaculares.",
        "w6_nom": "Calella de Palafrugell & Llafranc", "w6_desc": "Visitad Calella y haced el corto Camí de Ronda que la conecta con Llafranc. Dos pueblos pequeños y llenos de encanto, perfectos para pasear y cenar.",
        "w7_nom": "Ruta del Tren Petit 🚲", "w7_desc": "Esta antigua vía de tren se ha convertido en una vía verde ideal para caminar, correr o ir en bici hasta Palafrugell. Para volver, podéis coger el autobús desde la estación de Palafrugell hasta Palamós 🚌.",
        "bus_tit": "Bus urbano La Fosca – Palamós", "bus_desc": "En verano (finales de junio a principios de septiembre) hay el bus urbano de Moventis SARFA, línea L2, que conecta La Fosca con el centro de Palamós. La parada está en el Càmping Palamós / Cala Margarida. Horarios en: visitpalamos.cat/documentacio-turistica",
        "rest_fosca_tit": "Restaurantes — La Fosca",
        "rest_pal_tit": "Restaurantes — Palamós",
        "compra_tit": "Dónde hacer la compra",
        "aparc_tit": "Aparcamiento en La Fosca",
        "aparc_estiu1": "El camino de tierra del apartamento tiene aparcamiento gratuito. Normalmente podéis encontrar sitio sin problema a primera hora de la mañana o a partir de media tarde, cuando ya ha marchado la gente que viene a pasar el día. Yo siempre aparco allí.",
        "aparc_estiu2": "Si cuando llegáis el camino está lleno, la mejor opción es dejar el coche en la intersección entre el Camí de l'Església de La Fosca y la carretera de La Fosca. Hay aparcamiento de pago, pero a partir de la tarde podréis pasar al camino de tierra gratuito.",
        "aparc_estiu3": "⚠️  La zona de aparcamiento regulado de La Fosca (zona roja y azul) solo está habilitada del 15 de junio al 15 de septiembre.",
        "aparc_noestu": "Fuera de los meses de verano no hay ningún problema para aparcar. Podéis dejar el coche tranquilamente en la calle donde está el apartamento, en el camino de tierra, sin restricciones.",
        "pobles_tit": "Pueblos con encanto para visitar",
        "pobles_intro": "Si tenéis tiempo y coche, estos pueblos de la zona valen mucho la pena. En verano el aparcamiento en los pueblos de costa puede ser complicado — mejor ir a primera hora o por la tarde.",
        "footer": "Cualquier duda, estoy a vuestra disposición. ¡Buen descanso y disfrutad de La Fosca! 🌊",
        "spar_desc": "El supermercado de La Fosca, muy práctico si volvéis de las calas o de la playa. En verano abre todo el día.",
        "fleca_desc": "La panadería, justo delante del Spar. Pan y bollería de calidad. En verano abre por la mañana.",
        "rotllan_desc": "Una frutería de toda la vida con producto de muy buena calidad. Un poco cara, pero se nota la diferencia.",
        "mercadona_desc": "Hay que ir en coche, pero tiene mucho aparcamiento gratuito y los precios son buenos. La mejor opción para hacer la compra grande de la semana.",
        "bonpreu_desc": "A la entrada de La Fosca desde Palamós. Muy práctico si os falta algo y habéis venido paseando.",
        "isaac_desc": "Un lugar especial. Cocina de mercado con mucho producto local, en una masía del siglo XVIII. El menú de mediodía entre semana tiene una muy buena relación calidad-precio: 22€. Hay que ir en coche, pero vale muchísimo la pena.",
        "nautic_desc": "Restaurante con vistas al mar, ideal para una comida tranquila. Especialistas en arroces al mediodía. Se recomienda reservar.",
        "canquel_desc": "Muy buen menú entre semana por 21€, con paella y plato de temporada. Los fines de semana, menú especial a 30€. Vale la pena reservar.",
        "trias_desc": "Buen menú diario en un entorno elegante frente al mar. Consultad el precio actual en su web.",
        "bitacora_desc": "Un rincón que me ha conquistado. Voy de noche a cenar y siempre hay ambiente y mucha gente. Los platitos — pequeños, para compartir — no paran de sorprender. Precios muy razonables. No aceptan reservas pero te cogen el número y te avisan cuando haya mesa.",
        "txoko_desc": "Solo abren por la noche y no aceptan reservas. Pedid una botella de sidra y esperad que vayan pasando con las bandejas: pintxos calientes que salen de cocina sin parar. Déjaos llevar.",
        "canblau_desc": "Muy buen restaurante de pescado y arroces. No es de los más económicos, pero el producto es de primera y vale la pena.",
        "xiringuito_desc": "Justo en la playa, con terraza exterior. Comida sencilla y muy buena: tortilla de patatas, ensaladilla rusa, bocadillo de calamares, mejillones... Perfecto para un almuerzo informal.",
        "waves_desc": "Buena opción para cenar en La Fosca cuando no os queréis mover del barrio. Agradable.",
        "calella_desc": "Unidos por un Camí de Ronda precioso. Dos de los pueblos más bonitos de la Costa Brava.",
        "tamariu_desc": "Cala pequeña e íntima, poco masificada. Uno de los secretos mejor guardados de la zona.",
        "begur_desc": "Pueblo medieval con castillo y vistas impresionantes. Muy recomendable.",
        "pals_desc": "Núcleo medieval muy bien conservado en medio del Empordà. Muy fotogénico.",
        "peratallada_desc": "Uno de los pueblos medievales más bonitos de Cataluña. Se puede combinar perfectamente con Pals.",
        "platjadaro_desc": "Tiene un buen paseo marítimo y calle comercial. En el centro comercial es fácil aparcar y hay cine (ocineplatjadaro.es).",
    }
elif IDIOMA == "angles":
    T = {
        "intro": f"La Fosca is one of the most beautiful and exclusive areas of Palamós: a lovely, quiet cove, slightly away from the town centre but just a short walk from everything. From the beach you can explore spectacular sections of the Camí de Ronda, a coastal path I love and highly recommend. Palamós is also a charming town with a great seaside promenade, wonderful atmosphere and excellent food, especially for fish and seafood lovers.",
        "sub": "La Fosca · Palamós · Costa Brava",
        "platges_tit": "Beaches of La Fosca",
        "p1_nom": "The Small Beach", "p1_desc": "Just near the apartment, before reaching the main beach. There are rocks at the entrance but once inside it's fantastic — quiet, sheltered, and practically only visited by locals. Highly recommended.",
        "p2_nom": "La Fosca Beach", "p2_desc": "The main beach of the area, very complete. It has the characteristic rock in the centre — which is how La Fosca got its name. Large, with good atmosphere and facilities. Ideal for families.",
        "passejos_tit": "Walks — Camí de Ronda",
        "w1_nom": "Walking to Palamós  ★ recommended", "w1_desc": "The most direct route is to follow the La Fosca road, passing in front of Càmping Palamós — about 15–20 minutes on foot. There's no need to take the car: Palamós is a small town that's very pleasant to explore on foot.",
        "w2_nom": "Camí de Ronda: La Fosca – Cala Margarida – Palamós", "w2_desc": "If you'd rather walk along the coast to Palamós, take this short trail that starts from La Fosca and passes the fishermen's cottages at Cala Margarida. There are a few climbs, but it's beautiful. A good excuse to take your time.",
        "w3_nom": "La Fosca – Cala S'Alguer – Platja del Castell – Cala Canyers – Cala Corbs – Cala Estreta", "w3_desc": "A walk I love. It starts right at the end of La Fosca beach. As far as Platja del Castell it's comfortable and suitable for everyone. After that the terrain changes: ups and downs, roots, rocks. The trail continues to Calella de Palafrugell and Llafranc, but doing the whole thing and back is for serious walkers.",
        "w4_nom": "Sant Antoni de Calonge – Platja d'Aro", "w4_desc": "Sant Antoni is the natural continuation of Palamós, connected by the seafront promenade — you can walk there from the apartment. From there, the Camí de Ronda to Platja d'Aro is a beautiful coastal walk passing many hidden coves.",
        "w5_nom": "Platja d'Aro – S'Agaró", "w5_desc": "A very easy and flat walk, with spectacular views.",
        "w6_nom": "Calella de Palafrugell & Llafranc", "w6_desc": "Visit Calella and walk the short Camí de Ronda that connects it to Llafranc. Two small villages full of charm, perfect for a stroll and dinner.",
        "w7_nom": "Ruta del Tren Petit 🚲", "w7_desc": "This former railway line has been transformed into a beautiful greenway, perfect for walking, running or cycling all the way to Palafrugell. To return, take the bus from Palafrugell bus station to Palamós 🚌.",
        "bus_tit": "Local bus La Fosca – Palamós", "bus_desc": "In summer (late June to early September) there is a local bus by Moventis SARFA, line L2, connecting La Fosca with the centre of Palamós. The stop is at Càmping Palamós / Cala Margarida. Timetables at: visitpalamos.cat/documentacio-turistica",
        "rest_fosca_tit": "Restaurants — La Fosca",
        "rest_pal_tit": "Restaurants — Palamós",
        "compra_tit": "Food shopping",
        "aparc_tit": "Parking at La Fosca",
        "aparc_estiu1": "The dirt track next to the apartment has free parking. You can usually find a spot easily in the early morning or from mid-afternoon onwards, once the day visitors have left. I always park there.",
        "aparc_estiu2": "If the track is full when you arrive, the best option is to leave the car at the junction between Camí de l'Església de La Fosca and the La Fosca road. There's paid parking there, but from the afternoon onwards you'll be able to move to the free dirt track.",
        "aparc_estiu3": "⚠️  The regulated parking zone in La Fosca (red and blue zones) is only in operation from 15 June to 15 September.",
        "aparc_noestu": "Outside the summer months there are no parking restrictions. You can leave the car on the track right next to the apartment without any issues.",
        "pobles_tit": "Charming villages to visit",
        "pobles_intro": "If you have time and a car, these nearby villages are well worth a visit. In summer, parking in the coastal villages can be tricky — better to go early in the morning or in the afternoon.",
        "footer": "Any questions, I'm at your disposal. Enjoy your stay at La Fosca! 🌊",
        "spar_desc": "The local supermarket in La Fosca, very handy if you're coming back from the coves or the beach. Open all day in summer.",
        "fleca_desc": "The bakery, right opposite the Spar. Great bread and pastries. Open in the mornings in summer.",
        "rotllan_desc": "A traditional greengrocer with excellent quality produce. Slightly expensive, but you can taste the difference.",
        "mercadona_desc": "You need a car to get there, but it has plenty of free parking and good prices. The best option for a big weekly shop.",
        "bonpreu_desc": "At the entrance to La Fosca from Palamós. Very convenient if you need a few things and you've walked in from Palamós.",
        "isaac_desc": "A special place. Market cuisine with lots of local produce, set in an 18th-century farmhouse. The weekday lunch menu offers great value for money: 22€. You need a car, but it's absolutely worth it.",
        "nautic_desc": "A restaurant with sea views, perfect for a relaxed lunch. Rice dishes at lunchtime. Booking recommended.",
        "canquel_desc": "Great weekday lunch menu for 21€, with paella and a seasonal dish. Weekends have a special menu at 30€. Worth booking in advance.",
        "trias_desc": "Good daily menu in an elegant setting right on the seafront. Check the current price on their website.",
        "bitacora_desc": "A place that's won me over. I go for dinner at night and there's always atmosphere and plenty of people. The small sharing dishes never stop surprising you — they update the menu every season. Very reasonable prices. No reservations, but they take your number and call you when a table is free.",
        "txoko_desc": "Only open evenings, no reservations — the queues say it all. Order a bottle of cider, find a spot and wait for the hot pintxos that keep coming out of the kitchen. Let yourself go with the flow.",
        "canblau_desc": "Excellent fish and rice restaurant. Not the cheapest, but the quality is top notch and well worth it.",
        "xiringuito_desc": "Right on the beach, with outdoor seating. Simple and very good food: Spanish omelette, Russian salad, calamari sandwich, mussels... Perfect for a casual lunch.",
        "waves_desc": "A good dinner option in La Fosca when you don't want to go far. Pleasant.",
        "calella_desc": "Linked by a beautiful Camí de Ronda. Two of the most charming villages on the Costa Brava.",
        "tamariu_desc": "A small, intimate cove, not overcrowded. One of the best-kept secrets in the area.",
        "begur_desc": "Medieval village with a castle and impressive views. Highly recommended.",
        "pals_desc": "A beautifully preserved medieval village in the middle of the Empordà countryside. Very photogenic.",
        "peratallada_desc": "One of the most beautiful medieval villages in Catalonia. Can be combined perfectly with Pals.",
        "platjadaro_desc": "Has a nice seafront promenade and shopping street. Easy parking at the shopping centre, which also has a cinema (ocineplatjadaro.es).",
    }
else:  # alemany
    T = {
        "intro": f"La Fosca ist eine der schönsten und exklusivsten Gegenden von Palamós: eine wunderschöne, ruhige Bucht, etwas abseits vom Trubel, aber zu Fuß in wenigen Minuten von allem erreichbar. Vom Strand aus könnt ihr spektakuläre Abschnitte des Camí de Ronda entdecken, einen Küstenweg, den ich sehr liebe und sehr empfehle. Palamós ist auch ein charmantes Städtchen mit einer schönen Strandpromenade, großartiger Atmosphäre und exzellentem Essen.",
        "sub": "La Fosca · Palamós · Costa Brava",
        "platges_tit": "Strände von La Fosca",
        "p1_nom": "Der kleine Strand", "p1_desc": "Direkt in der Nähe der Wohnung, vor dem Hauptstrand. Am Eingang gibt es Steine, aber drinnen ist es fantastisch — ruhig, geschützt und praktisch nur von Einheimischen besucht. Sehr empfehlenswert.",
        "p2_nom": "Strand von La Fosca", "p2_desc": "Der Hauptstrand des Viertels, sehr vollständig. Er hat den charakteristischen Felsen in der Mitte — daher der Name La Fosca. Groß, mit guter Atmosphäre und Einrichtungen. Ideal für Familien.",
        "passejos_tit": "Spaziergänge — Camí de Ronda",
        "w1_nom": "Zu Fuß nach Palamós  ★ empfohlen", "w1_desc": "Der direkteste Weg ist die Straße von La Fosca entlangzugehen, am Càmping Palamós vorbei — etwa 15–20 Minuten zu Fuß. Das Auto ist nicht nötig: Palamós ist ein kleines Städtchen, das man sehr angenehm zu Fuß erkunden kann.",
        "w2_nom": "Camí de Ronda: La Fosca – Cala Margarida – Palamós", "w2_desc": "Wenn ihr lieber an der Küste entlang nach Palamós wandern möchtet, nehmt diesen kurzen Weg, der von La Fosca aus an den Fischerhäuschen der Cala Margarida vorbeiführt. Es gibt einige Anstiege, aber es ist sehr schön.",
        "w3_nom": "La Fosca – Cala S'Alguer – Platja del Castell – Cala Canyers – Cala Corbs – Cala Estreta", "w3_desc": "Ein Spaziergang, den ich liebe. Er beginnt am Ende des Strands von La Fosca. Bis zur Platja del Castell ist der Weg bequem. Danach wird das Gelände schwieriger: Anstiege, Abstiege, Wurzeln. Der Weg führt weiter bis nach Calella de Palafrugell und Llafranc, aber die ganze Strecke hin und zurück ist für erfahrene Wanderer.",
        "w4_nom": "Sant Antoni de Calonge – Platja d'Aro", "w4_desc": "Sant Antoni ist die natürliche Fortsetzung von Palamós, verbunden durch die Strandpromenade — zu Fuß von der Wohnung aus erreichbar. Von dort ist der Camí de Ronda bis Platja d'Aro ein wunderschöner Küstenspaziergang.",
        "w5_nom": "Platja d'Aro – S'Agaró", "w5_desc": "Ein sehr einfacher und flacher Spaziergang mit spektakulären Ausblicken.",
        "w6_nom": "Calella de Palafrugell & Llafranc", "w6_desc": "Besucht Calella und macht den kurzen Camí de Ronda, der es mit Llafranc verbindet. Zwei kleine Orte voller Charme, perfekt zum Schlendern und Abendessen.",
        "w7_nom": "Ruta del Tren Petit 🚲", "w7_desc": "Diese ehemalige Bahnstrecke wurde in einen schönen Grünweg umgewandelt, ideal zum Wandern, Joggen oder Radfahren bis nach Palafrugell. Für die Rückfahrt empfehle ich den Bus vom Busbahnhof Palafrugell nach Palamós 🚌.",
        "bus_tit": "Stadtbus La Fosca – Palamós", "bus_desc": "Im Sommer (Ende Juni bis Anfang September) gibt es den Stadtbus von Moventis SARFA, Linie L2, der La Fosca mit dem Zentrum von Palamós verbindet. Die Haltestelle ist beim Càmping Palamós / Cala Margarida. Fahrplan unter: visitpalamos.cat/documentacio-turistica",
        "rest_fosca_tit": "Restaurants — La Fosca",
        "rest_pal_tit": "Restaurants — Palamós",
        "compra_tit": "Einkaufen",
        "aparc_tit": "Parken in La Fosca",
        "aparc_estiu1": "Der Schotterweg neben der Wohnung hat kostenlose Parkplätze. Normalerweise findet ihr früh morgens oder ab Mitte Nachmittag problemlos einen Platz, wenn die Tagesbesucher abgefahren sind. Ich parke dort immer.",
        "aparc_estiu2": "Wenn der Weg voll ist, ist die beste Option, das Auto an der Kreuzung zwischen dem Camí de l'Església de La Fosca und der Straße von La Fosca zu parken. Dort gibt es kostenpflichtiges Parken, aber ab dem Nachmittag könnt ihr auf den kostenlosen Schotterweg wechseln.",
        "aparc_estiu3": "⚠️  Die regulierte Parkzone in La Fosca (rote und blaue Zone) ist nur vom 15. Juni bis 15. September in Betrieb.",
        "aparc_noestu": "Außerhalb der Sommermonate gibt es keine Parkbeschränkungen. Ihr könnt das Auto problemlos auf dem Weg neben der Wohnung abstellen.",
        "pobles_tit": "Charmante Dörfer zum Besuchen",
        "pobles_intro": "Wenn ihr Zeit und ein Auto habt, lohnen sich diese Dörfer sehr. Im Sommer kann das Parken in den Küstenorten schwierig sein — am besten früh morgens oder am Nachmittag fahren.",
        "footer": "Bei Fragen stehe ich euch gerne zur Verfügung. Erholt euch gut und genießt La Fosca! 🌊",
        "spar_desc": "Der Supermarkt von La Fosca, sehr praktisch, wenn ihr von den Buchten oder dem Strand zurückkommt. Im Sommer den ganzen Tag geöffnet.",
        "fleca_desc": "Die Bäckerei, direkt gegenüber dem Spar. Gutes Brot und Gebäck. Im Sommer morgens geöffnet.",
        "rotllan_desc": "Ein traditioneller Gemüsehändler mit sehr guter Qualität. Etwas teurer, aber man schmeckt den Unterschied.",
        "mercadona_desc": "Man muss mit dem Auto hinfahren, aber es hat viel kostenlosen Parkplatz und gute Preise. Die beste Option für den großen Wocheneinkauf.",
        "bonpreu_desc": "Am Eingang von La Fosca von Palamós aus. Sehr praktisch, wenn euch etwas fehlt und ihr von Palamós hergelaufen seid.",
        "isaac_desc": "Ein besonderer Ort. Marktküche mit vielen lokalen Produkten in einem Bauernhof aus dem 18. Jahrhundert. Das Mittagsmenü unter der Woche bietet ein sehr gutes Preis-Leistungs-Verhältnis: 22€. Man muss mit dem Auto hinfahren, aber es lohnt sich sehr.",
        "nautic_desc": "Restaurant mit Meerblick, ideal für ein entspanntes Mittagessen. Spezialisiert auf Reisgerichte. Reservierung empfohlen.",
        "canquel_desc": "Tolles Mittagsmenü unter der Woche für 21€, mit Paella und Saisonalitem. Am Wochenende gibt es ein Sondermenü für 30€. Reservierung lohnt sich.",
        "trias_desc": "Gutes Tagesmenü in einem eleganten Ambiente direkt am Meer. Aktuellen Preis auf der Website prüfen.",
        "bitacora_desc": "Ein Ort, der mich begeistert hat. Ich gehe abends essen und es herrscht immer Stimmung und viel Betrieb. Die kleinen Gerichte zum Teilen überraschen immer wieder — die Karte wird jede Saison erneuert. Sehr vernünftige Preise. Keine Reservierungen, aber sie nehmen eure Nummer und rufen an, wenn ein Tisch frei ist.",
        "txoko_desc": "Nur abends geöffnet, keine Reservierungen — die Schlangen sagen alles. Bestellt eine Flasche Cidre, findet einen Platz und wartet auf die heißen Pintxos, die aus der Küche kommen. Lasst euch treiben.",
        "canblau_desc": "Ausgezeichnetes Fisch- und Reisrestaurant. Nicht das günstigste, aber die Qualität ist erstklassig.",
        "xiringuito_desc": "Direkt am Strand, mit Außenterrasse. Einfaches und sehr gutes Essen: Tortilla, russischer Salat, Tintenfisch-Sandwich, Muscheln... Perfekt für ein ungezwungenes Mittagessen.",
        "waves_desc": "Gute Abendessen-Option in La Fosca, wenn ihr euch nicht weit bewegen möchtet. Angenehm.",
        "calella_desc": "Durch einen wunderschönen Camí de Ronda verbunden. Zwei der charmantesten Dörfer der Costa Brava.",
        "tamariu_desc": "Kleine, intime Bucht, nicht überlaufen. Eines der bestgehüteten Geheimnisse der Gegend.",
        "begur_desc": "Mittelalterliches Dorf mit Burg und beeindruckenden Ausblicken. Sehr empfehlenswert.",
        "pals_desc": "Sehr gut erhaltener mittelalterlicher Kern mitten im Empordà. Sehr fotogen.",
        "peratallada_desc": "Eines der schönsten mittelalterlichen Dörfer Kataloniens. Lässt sich wunderbar mit Pals kombinieren.",
        "platjadaro_desc": "Hat eine schöne Strandpromenade und Einkaufsstraße. Am Einkaufszentrum leicht zu parken, dort gibt es auch ein Kino (ocineplatjadaro.es).",
    }

# ── Helpers ───────────────────────────────────────
def ST(name, **kw):
    return ParagraphStyle(name, **kw)

S = {
    "title":     ST("title", fontName="Helvetica-Bold", fontSize=21, textColor=TERRA_D, leading=26, spaceBefore=0.3*cm, spaceAfter=0.05*cm),
    "salut":     ST("salut", fontName="Helvetica-Bold", fontSize=13.5, textColor=TERRA, leading=18, spaceBefore=0, spaceAfter=0.05*cm),
    "sub":       ST("sub", fontName="Helvetica", fontSize=9.5, textColor=GREY, leading=13, spaceAfter=0.3*cm),
    "intro":     ST("intro", fontName="Helvetica", fontSize=10.2, textColor=MID, leading=15.5, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
    "wt":        ST("wt", fontName="Helvetica-Bold", fontSize=10, textColor=DARK, leading=14, spaceBefore=0.28*cm, spaceAfter=0.04*cm),
    "body":      ST("body", fontName="Helvetica", fontSize=9.7, textColor=MID, leading=14.5, spaceAfter=0.04*cm, alignment=TA_JUSTIFY),
    "rname":     ST("rname", fontName="Helvetica-Bold", fontSize=10.2, textColor=DARK, leading=14, spaceBefore=0.22*cm, spaceAfter=0.04*cm),
    "rbody":     ST("rbody", fontName="Helvetica", fontSize=9.6, textColor=MID, leading=14, spaceAfter=0.04*cm, alignment=TA_JUSTIFY),
    "link":      ST("link", fontName="Helvetica", fontSize=8.5, textColor=TERRA_D, leading=12, spaceAfter=0.02*cm),
    "note":      ST("note", fontName="Helvetica-Oblique", fontSize=9, textColor=GREY, leading=13, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
    "village":   ST("village", fontName="Helvetica", fontSize=9.7, textColor=MID, leading=14.5, spaceAfter=0.14*cm),
    "footer":    ST("footer", fontName="Helvetica-Oblique", fontSize=9, textColor=GREY, alignment=TA_CENTER),
    "pb":        ST("pb", fontName="Helvetica", fontSize=9.6, textColor=MID, leading=14, spaceAfter=0.1*cm, alignment=TA_JUSTIFY),
}

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
        c.line(0.5*cm, 0, self.width - 0.5*cm, 0)

def lnk(label, url):
    return Paragraph(f'<font color="#A67550">{label}:</font> <a href="{url}"><font color="#A67550">{url}</font></a>', S["link"])

def rest(items):
    story = []
    for i, (name, loc, desc, links) in enumerate(items):
        block = []
        if i > 0: block.append(Div())
        loc_s = f' <font color="#9A8880" size="9">· {loc}</font>' if loc else ""
        block.append(Paragraph(f'{name}{loc_s}', S["rname"]))
        block.append(Paragraph(desc, S["rbody"]))
        for lbl, url in links: block.append(lnk(lbl, url))
        story.append(KeepTogether(block))
    return story

# ── Document ──────────────────────────────────────
doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=L_MAR, rightMargin=R_MAR, topMargin=T_MAR, bottomMargin=B_MAR)
frame = Frame(L_MAR, B_MAR, TW, PAGE_H - T_MAR - B_MAR, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="main")
doc.addPageTemplates([PageTemplate(id="main", frames=[frame])])

story = []

if HAS_HERO:
    HERO_H = TW * (560/1600)
    story.append(HeroImage(HERO_DST, TW, HERO_H, caption="Cala S'Alguer · Palamós"))
    story.append(Spacer(1, 0.5*cm))

story.append(Paragraph(NAME, S["title"]))
story.append(Paragraph(SALUT, S["salut"]))
story.append(Paragraph(T["sub"], S["sub"]))
story.append(Paragraph(T["intro"], S["intro"]))
story.append(Spacer(1, 0.4*cm))

# Platges
story.append(KeepTogether([SecHeader("🏖️", T["platges_tit"])]))
story.append(Spacer(1, 0.18*cm))
story.append(KeepTogether([Paragraph(T["p1_nom"], S["wt"]), Paragraph(T["p1_desc"], S["body"])]))
story.append(KeepTogether([Div(), Paragraph(T["p2_nom"], S["wt"]), Paragraph(T["p2_desc"], S["body"])]))
story.append(Spacer(1, 0.45*cm))

# Passejos
story.append(KeepTogether([SecHeader("🌿", T["passejos_tit"])]))
story.append(Spacer(1, 0.18*cm))
for k in ["w1","w2","w3","w4","w5","w6","w7"]:
    story.append(KeepTogether([Paragraph(T[f"{k}_nom"], S["wt"]), Paragraph(T[f"{k}_desc"], S["body"])]))
story.append(Spacer(1, 0.45*cm))

# Bus (estiu)
if ESTIU:
    story.append(KeepTogether([SecHeader("🚌", T["bus_tit"])]))
    story.append(Spacer(1, 0.18*cm))
    story.append(Paragraph(T["bus_desc"], S["body"]))
    story.append(Spacer(1, 0.45*cm))

# Restaurants La Fosca
story.append(KeepTogether([SecHeader("🍽️", T["rest_fosca_tit"])]))
story.append(Spacer(1, 0.18*cm))
for b in rest([
    ("Xiringuito de Can Blau", "La Fosca", T["xiringuito_desc"], [("📍", "https://g.co/kgs/qcuJzdf")]),
    ("Waves", "La Fosca", T["waves_desc"], [("📍", "https://g.co/kgs/4hFnUSk")]),
]): story.append(b)
story.append(Spacer(1, 0.45*cm))

# Restaurants Palamós
story.append(KeepTogether([SecHeader("🍽️", T["rest_pal_tit"])]))
story.append(Spacer(1, 0.18*cm))
for b in rest([
    ("Sala de L'Isaac", "Llofriu", T["isaac_desc"], [("📋", "https://www.salagran.com/salaisaac/la-carta/"), ("📍", "https://g.co/kgs/SmXVEuY")]),
    ("Restaurant Nàutic", "Palamós", T["nautic_desc"], [("📍", "https://g.co/kgs/X6GFeBf")]),
    ("Can Quel", "Palamós", T["canquel_desc"], [("🌐", "https://restaurantcanquelpalamos.com/"), ("📍", "https://g.co/kgs/QX5QpQG")]),
    ("Hotel Trias", "Palamós", T["trias_desc"], [("🌐", "https://www.hoteltrias.com/restaurante.html")]),
    ("Bitàcora", "Palamós", T["bitacora_desc"], []),
    ("Txoko Donostiarra", "Palamós", T["txoko_desc"], [("📍", "https://g.co/kgs/1Htn7D")]),
    ("Can Blau", "Palamós", T["canblau_desc"], [("📍", "https://maps.app.goo.gl/A8Pb68BSdD5dFofh8")]),
]): story.append(b)
story.append(Spacer(1, 0.45*cm))

# Compra
story.append(KeepTogether([SecHeader("🛒", T["compra_tit"])]))
story.append(Spacer(1, 0.18*cm))
compra_items = []
if ESTIU:
    compra_items += [
        ("Spar", "La Fosca", T["spar_desc"], [("📍", "https://www.google.com/maps/place/Spar+La+Fosca/@41.8601561,3.1458594,17z")]),
        ("La Fleca de l'Empordà", "La Fosca", T["fleca_desc"], [("🌐", "https://www.lafleca.com/ca/botigues/palamos-la-fosca/")]),
    ]
compra_items += [
    ("Rotllan", "Palamós", T["rotllan_desc"], [("📍", "https://g.co/kgs/XQuBbLf")]),
    ("Mercadona", "Palamós", T["mercadona_desc"], []),
    ("Bon Preu", "Palamós", T["bonpreu_desc"], []),
]
for b in rest(compra_items): story.append(b)
story.append(Spacer(1, 0.45*cm))

# Aparcament
story.append(KeepTogether([SecHeader("🚗", T["aparc_tit"])]))
story.append(Spacer(1, 0.18*cm))
if ESTIU:
    story.append(Paragraph(T["aparc_estiu1"], S["pb"]))
    story.append(Paragraph(T["aparc_estiu2"], S["pb"]))
    story.append(Paragraph(T["aparc_estiu3"], S["note"]))
else:
    story.append(Paragraph(T["aparc_noestu"], S["pb"]))
story.append(Spacer(1, 0.45*cm))

# Pobles
story.append(KeepTogether([SecHeader("🏡", T["pobles_tit"])]))
story.append(Spacer(1, 0.18*cm))
story.append(Paragraph(T["pobles_intro"], S["body"]))
story.append(Spacer(1, 0.15*cm))
pobles = [
    ("Calella de Palafrugell – Llafranc", "12 km", T["calella_desc"]),
    ("Tamariu", "17 km", T["tamariu_desc"]),
    ("Begur", "17 km", T["begur_desc"]),
    ("Pals", "20 km", T["pals_desc"]),
    ("Peratallada", "22 km", T["peratallada_desc"]),
    ("Platja d'Aro", "13 km", T["platjadaro_desc"]),
]
for nom, dist, desc in pobles:
    story.append(KeepTogether([Paragraph(
        f'<b>{nom}</b>  <font color="#9A8880" size="9">({dist})</font><br/>'
        f'<font size="9.3" color="#5C4035">{desc}</font>', S["village"])]))

if NOTES:
    story.append(Spacer(1, 0.4*cm))
    story.append(KeepTogether([SecHeader("📝", "Notes")]))
    story.append(Spacer(1, 0.18*cm))
    story.append(Paragraph(NOTES, S["body"]))

story.append(Spacer(1, 0.6*cm))
story.append(HRFlowable(width=TW, thickness=0.6, color=BORDER, spaceAfter=0.2*cm))
story.append(Paragraph(T["footer"], S["footer"]))

doc.build(story)
print(f"✅ PDF generat: {OUT}")
PYEOF

STATUS=$?
echo ""
if [ $STATUS -eq 0 ]; then
  echo "✅ PDF guardat a l'Escriptori:"
  echo "   $OUTPUT"
  echo ""
  open "$OUTPUT"
else
  echo "❌ Error generant el PDF. Comprova que tens Python3 i les llibreries instal·lades."
fi

echo ""
read -p "Prem Enter per tancar..."
