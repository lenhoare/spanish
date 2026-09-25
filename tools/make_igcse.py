"""Builds the La Isla de los Retos lesson files (lessons/igcse/*.json).
Source: lessons/spanish_igcse_summary.md.   Run:  python tools/make_igcse.py
"""
import json, os, textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "lessons", "igcse")


def md(s):
    return textwrap.dedent(s).strip("\n")


def card(id, q, answers, hint, expl):
    return {"id": id, "question": q, "answers": answers, "hint": hint, "explanation": expl}


def mc(id, q, choices, correct, hint, expl, **kw):
    d = {"id": id, "question": q, "choices": choices, "correct": correct, "hint": hint, "explanation": expl}
    d.update(kw)
    return d


HOLIDAY_WORDS = ["vacacion", "viaj", "fui", "fuimos", "visit", "playa", "hotel", "camping", "españa", "francia", "italia",
                 "costa", "montaña", "ciudad", "mar", "aloj", "qued", "turismo", "excursi", "avión", "avion", "familia",
                 "verano", "extranjero", "piscina", "sol", "pueblo", "parque", "museo"]

vacaciones = {
    "format": "lesson-island/1",
    "title": "Las vacaciones",
    "subject": "IGCSE - Módulo 1",
    "intro": "Holidays, hotels and disasters! The preterite, the imperfect and how to write answers worth five stars.",
    "whiteboard": {"pages": [
        {"title": "¿Qué hiciste?", "markdown": md("""
          # ¿Qué hiciste? - the preterite
          For **completed actions** in the past: *ayer, el año pasado, hace dos años...*

          | | ir / ser | hacer | tener | ver |
          |---|---|---|---|---|
          | yo | **fui** | **hice** | **tuve** | **vi** |
          | nosotros | **fuimos** | **hicimos** | **tuvimos** | **vimos** |

          Regular: visit**é**, com**í**, sal**í** - and nosotros: visit**amos**, com**imos**

          - Hace dos años **fui** de vacaciones a Benidorm con mi familia.
          - **Viajamos** en avión y en autocar.
          - **Hice** turismo, **saqué** fotos y **compré** recuerdos.
          - **Aprendí** a bucear y **tomé** el sol.
        """)},
        {"title": "Pretérito o imperfecto", "markdown": md("""
          # Preterite or imperfect?
          **Preterite** - a single, finished action: *fui, me quedé, pasé*
          **Imperfect** - description (what it *was like*) or what you *used to* do:
          *era, estaba, tenía, había, hacía, íbamos*

          - Saqué fotos cuando **estaba** en las montañas.
          - Me quedé en una pensión, pero no **tenía** piscina.
          - De joven, **íbamos** a la playa y **hacíamos** barbacoa.
          - El hotel **tenía** vistas al mar y **era** muy cómodo.
          - Ayer lo **pasé** muy bien porque **hice** el vago.

          > Using BOTH tenses in one answer shows the examiner real range.
        """)},
        {"title": "El alojamiento", "markdown": md("""
          # ¿Dónde te alojaste?
          **Me alojé / Me quedé** en... - **Nos alojamos / Nos quedamos** en...
          un albergue juvenil, un apartamento, un camping, un hotel de cinco estrellas,
          un parador, una casa rural, una pensión

          **Estaba** cerca de la playa / en el centro / en las afueras.
          **Era** acogedor, antiguo, lujoso, moderno, ruidoso, tranquilo...
          **Tenía / Había** piscina cubierta, gimnasio, restaurante, aparcamiento...
          **No tenía ni** wifi **ni** aire acondicionado. **Tampoco tenía** ascensor.
        """)},
        {"title": "¡Qué desastre!", "markdown": md("""
          # Problemas en las vacaciones
          - **Perdí** el equipaje / la cartera / la maleta / las llaves
          - **Tuve** un accidente / un pinchazo / un retraso
          - **Tuve que** esperar mucho tiempo / ir a la comisaría
          - **Cuando llegamos**, era muy tarde y la recepción ya estaba cerrada

          # Quiero quejarme
          La ducha **no funciona**. La habitación **está sucia**.
          **No hay** toallas. **Necesito** papel higiénico.
          **Quiero** hablar con el director. **Es inaceptable.**
        """)},
        {"title": "Opiniones", "markdown": md("""
          # ¿Qué tal lo pasaste?
          **Lo pasé** bomba / fenomenal / bien / mal / fatal
          **Fue** inolvidable / increíble / impresionante / un desastre
          **Lo mejor fue** cuando aprendí a bucear. **Lo peor fue** cuando perdí mi móvil.
          ¡Qué horror! ¡Qué guay! ¡Qué desastre!

          # Time phrases
          **hace** una semana / dos años - **el verano pasado** - **el primer día** -
          **al día siguiente** - **el último día** - **el año que viene**
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          The postboxes mark your writing like an examiner. One star for each:

          1. A **verb in the right tense** - *fui, visité*
          2. A **time phrase** - *el verano pasado, hace dos años*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *lo mejor fue, me encantó*
          5. A **second tense** - *era muy bonito, el año que viene voy a volver*

          > **El verano pasado fui** a Italia con mi familia. **Lo mejor fue** la comida,
          > **sin embargo** el hotel **era** muy ruidoso.
        """)},
    ]},
    "cards": [
        card("r1-fui", "How do you say \"I went\" in Spanish?", ["fui", "yo fui"], "Preterite of ir - page 1.", "Fui - the same as 'I was' (ser)!"),
        card("r1-alojamos", "El año pasado ____ en un camping.\n(alojarse - \"we stayed\")", ["nos alojamos"], "Reflexive verb: nos + nosotros form - page 3.", "Nos alojamos en un camping."),
        mc("r1-ibamos", "De joven, ____ a la playa todos los veranos.", ["íbamos", "fuimos", "vamos", "iremos"], 0, "'Used to' = imperfect - page 2.", "Íbamos - imperfect of ir for things you used to do."),
        card("r1-inolvidable", "Translate into Spanish:\n\"It was unforgettable.\"", ["fue inolvidable", "era inolvidable"], "Page 5 - opinions.", "Fue inolvidable."),
        mc("r1-tenia", "El hotel ____ vistas al mar y ____ muy cómodo.", ["tenía / era", "tuvo / fue", "tiene / fue", "tenía / fue"], 0, "Describing the hotel = imperfect - page 2.", "Tenía / era - description uses the imperfect."),
        card("r1-maleta", "Translate into Spanish:\n\"I lost my suitcase.\"", ["perdí mi maleta", "perdí la maleta", "yo perdí mi maleta"], "Page 4 - problems.", "Perdí mi maleta. ¡Qué desastre!"),
    ],
    "chests": [
        mc("r1-pension", "\"una pensión\" is...", ["a guest house", "a pension fund", "a campsite", "a youth hostel"], 0, "Page 3.", "Una pensión = a guest house.", level=1),
        mc("r1-bomba", "\"Lo pasé bomba\" means...", ["I had a great time", "I had an accident", "It was a disaster", "I was bored"], 0, "Page 5.", "Lo pasé bomba = I had a great time.", level=1),
        mc("r1-tormenta", "\"Hubo tormenta\" means...", ["It was stormy", "It was foggy", "It was windy", "It rained a little"], 0, "Weather in the past.", "Hubo tormenta = there was a storm.", level=2),
        mc("r1-ni", "\"No tenía ni piscina ni gimnasio\" means...", ["It had neither a pool nor a gym", "It had a pool but no gym", "It had a pool and a gym", "It didn't have a pool, just a gym"], 0, "Page 3.", "Ni... ni... = neither... nor...", level=2),
        mc("r1-estaba", "Saqué fotos cuando ____ en las montañas.", ["estaba", "estuve", "estoy", "estaré"], 0, "Background description = imperfect - page 2.", "Estaba - 'when I was (there)' is background.", level=3),
        mc("r1-pase", "Ayer lo ____ muy bien porque hice el vago.", ["pasé", "pasaba", "paso", "pasaré"], 0, "Ayer + one finished event = preterite - page 2.", "Lo pasé muy bien.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "question": "¿Adónde fuiste de vacaciones el año pasado?", "tense": "preterite",
         "topic_words": HOLIDAY_WORDS, "stars_needed": 3,
         "chips": ["el año pasado", "fui a", "con mi familia", "porque", "lo mejor fue", "sin embargo", "era"]},
        {"kind": "postcard", "question": "Cuando eras más joven, ¿qué hacías durante las vacaciones?", "tense": "imperfect",
         "topic_words": HOLIDAY_WORDS + ["íbamos", "ibamos", "jugaba", "hacía", "hacia"], "stars_needed": 3},
        {"kind": "postcard", "question": "¿Qué te gusta hacer de vacaciones? ¿Por qué?", "tense": "present",
         "topic_words": HOLIDAY_WORDS + ["me gusta", "nadar", "tomar", "descansar", "prefiero"], "stars_needed": 4},
        {"kind": "notice", "intro": "The storm broke the notice! Write each verb in the right form to fix it.",
         "text": "A menudo, la gente {1} las vacaciones en la montaña y, si hace buen tiempo, es divertido {2} al aire libre. "
                 "Según una encuesta, el invierno pasado muchas familias {3} en apartamentos en vez de en hoteles {4}, "
                 "porque un apartamento {5} más barato y más {6}. El año que viene yo {7} la costa del norte de España "
                 "y tengo la intención de {8} excursiones a {9} lugares de interés.",
         "hint": "Think: what time frame? Who is doing it? Does the adjective agree?",
         "gaps": [
             {"verb": "pasar", "answers": ["pasa"]},
             {"verb": "estar", "answers": ["estar"]},
             {"verb": "quedarse", "answers": ["se quedaron"]},
             {"verb": "lujoso", "answers": ["lujosos"]},
             {"verb": "ser", "answers": ["es", "era"]},
             {"verb": "cómodo", "answers": ["cómodo"]},
             {"verb": "visitar", "answers": ["visitaré", "voy a visitar"]},
             {"verb": "hacer", "answers": ["hacer"]},
             {"verb": "mucho", "answers": ["muchos"]},
         ]},
        {"kind": "detective", "sign": "Hotel Paraíso", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Isabel", "bubble": "¡Hotel horroroso!", "character": "character-female-b",
              "review": "# Isabel-98 (La Palma)\n\n¡Hotel horroroso! Pasé un finde en este hotel y no era nada barato - 150 € por noche. ¡Qué timo! Las habitaciones estaban muy sucias, la ducha estaba estropeada y no había toallas. También había basura en la piscina. Cuando fuimos a cenar, la comida estaba fría y había un insecto en mi sopa. Pero lo peor fue que el recepcionista tenía muy mala actitud."},
             {"name": "Tomás", "bubble": "¡Experiencia malísima!", "character": "character-male-d",
              "review": "# TomásFG (Bilbao)\n\nExperiencia malísima. No recomiendo este hotel. No tenía wifi ni aire acondicionado en las habitaciones. Tampoco tenía aparcamiento. El gimnasio no estaba abierto y el ascensor estaba estropeado. Había una discoteca que tenía la música muy alta, y por eso era imposible dormir. Además, el camarero en el restaurante era muy maleducado. Pero lo peor fue que había una serpiente en el balcón. ¡Qué miedo!"},
         ],
         "questions": [
             mc("d1", "¿Quién menciona la falta de limpieza?", ["Isabel", "Tomás", "Los dos"], 0, "Who says things were dirty (sucias)?", "Isabel - las habitaciones estaban muy sucias."),
             mc("d2", "¿Quién menciona a los empleados del hotel?", ["Isabel", "Tomás", "Los dos"], 2, "Look for the receptionist and the waiter.", "Los dos - el recepcionista (Isabel) y el camarero (Tomás)."),
             mc("d3", "¿Quién menciona la comida?", ["Isabel", "Tomás", "Los dos"], 0, "Who had dinner?", "Isabel - la comida estaba fría."),
             mc("d4", "¿Quién menciona el ruido?", ["Isabel", "Tomás", "Los dos"], 1, "Who couldn't sleep?", "Tomás - la discoteca tenía la música muy alta."),
             mc("d5", "¿Quién menciona las instalaciones deportivas?", ["Isabel", "Tomás", "Los dos"], 1, "Who mentions the gym?", "Tomás - el gimnasio no estaba abierto."),
             mc("d6", "¿Quién menciona el precio?", ["Isabel", "Tomás", "Los dos"], 0, "Who mentions euros?", "Isabel - 150 € por noche. ¡Qué timo!"),
             mc("d7", "¿Quién menciona el cuarto de baño?", ["Isabel", "Tomás", "Los dos"], 0, "Who mentions the shower and towels?", "Isabel - la ducha estaba estropeada y no había toallas."),
             mc("d8", "¿Quién menciona un reptil?", ["Isabel", "Tomás", "Los dos"], 1, "Una serpiente is a reptile...", "Tomás - ¡una serpiente en el balcón!"),
         ]},
    ],
    "sweets": [
        {"id": "r1-sweet-ideal", "kind": "hidden", "at": [250.0, 0.92], "question": "¿Cómo serían tus vacaciones ideales?",
         "sentence": {"question": "A message in a bottle: ¿Cómo serían tus vacaciones ideales?", "tense": "conditional",
                      "topic_words": HOLIDAY_WORDS + ["ideal", "iría", "iria", "me gustaría", "me gustaria"], "stars_needed": 3}},
        {"id": "r1-sweet-problema", "kind": "traveller", "question": "Háblame de un problema que tuviste durante las vacaciones.",
         "sentence": {"question": "El viajero asks: Háblame de un problema que tuviste durante las vacaciones.", "tense": "preterite",
                      "topic_words": HOLIDAY_WORDS + ["perdí", "perdi", "tuve", "problema", "accidente", "maleta", "cartera", "llaves", "retraso"],
                      "stars_needed": 3}},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Unas vacaciones inolvidables! You conquered Isla 1."},
}

SCHOOL_WORDS = ["instituto", "insti", "colegio", "escuela", "clase", "asignatura", "profesor", "alumn", "estudi", "aprend",
                "uniforme", "norma", "regla", "deberes", "examen", "nota", "recreo", "biblioteca", "laboratorio", "patio",
                "matemáticas", "matematicas", "ciencias", "historia", "inglés", "ingles", "química", "quimica", "dibujo",
                "informática", "informatica", "música", "musica", "idioma", "educación", "educacion", "gimnasio", "polideportivo",
                "excursi", "visita", "viaje", "director", "universidad", "bachillerato"]

instituto = {
    "format": "lesson-island/1",
    "title": "El instituto",
    "subject": "IGCSE - Módulo 2",
    "intro": "Subjects, teachers, rules and school trips - and how your school used to be.",
    "whiteboard": {"pages": [
        {"title": "Mis asignaturas", "markdown": md("""
          # Mis asignaturas
          **Estudio / Aprendo**... las matemáticas, las ciencias, la química, la historia, el dibujo,
          la informática, la educación física, el inglés...

          - **Me encanta** la química **porque** el profesor explica bien.
          - **Me interesa** la historia, **pero** es difícil.
          - **No me gusta nada** el dibujo **ya que** es aburrido.
          - **Mi asignatura preferida es** la informática.

          > **Tengo** química **los martes** a las once. - *I have chemistry on Tuesdays at eleven.*
          > Days: lunes, martes, miércoles, jueves, viernes. Time: **es la una, son las once**.
        """)},
        {"title": "Comparaciones", "markdown": md("""
          # Comparatives
          **más** + adjective + **que** - more ... than
          **menos** + adjective + **que** - less ... than
          **tan** + adjective + **como** - as ... as

          - La química es **más** interesante **que** la historia.
          - El dibujo es **menos** útil **que** la informática.
          - Mi profesor de inglés es **tan** simpático **como** mi profesora de ciencias.
          - **mejor** que (better than) / **peor** que (worse than)

          > The adjective agrees: las ciencias son más divertid**as**.
        """)},
        {"title": "Las normas", "markdown": md("""
          # Las normas del insti
          **Está prohibido** + infinitive: está prohibido **usar** el móvil en clase
          **No se permite** + infinitive: no se permite **llevar** maquillaje
          **Hay que / Tenemos que / Se debe** + infinitive: hay que **ser** puntual

          **Tenemos que llevar** uniforme: una chaqueta, una corbata, una falda, unos pantalones grises...

          # ¿Qué opinas?
          Creo que las normas son **justas / injustas / necesarias / tontas**.
          **Estoy a favor del** uniforme **porque**... - **Estoy en contra del** uniforme **ya que**...
        """)},
        {"title": "La escuela primaria", "markdown": md("""
          # ¿Cómo era tu escuela primaria?
          The **imperfect** describes how things *were* and what you *used to do*:

          - Mi escuela primaria **era** pequeña y **estaba** en el centro del pueblo.
          - **No había** laboratorios, pero **había** un patio grande.
          - Los profesores **eran** muy amables.
          - **Tenía** muchos amigos y **jugábamos** al fútbol en el recreo.
          - **No teníamos** que llevar uniforme.

          > **era, estaba, había, tenía, jugaba, llevaba** - use them to add a second tense!
        """)},
        {"title": "Extraescolares", "markdown": md("""
          # Las actividades extraescolares
          **Soy miembro del** club de ajedrez / del coro / del equipo de baloncesto.
          **Toco la trompeta desde hace dos años.** - *I've been playing the trumpet for two years.*
          *desde hace* + time + **present tense** = have been doing for...

          # Éxitos
          **El año pasado gané** un premio / un concurso. **Saqué** buenas notas.
          **Participamos** en un concurso de bandas. ¡Fue genial!

          # Problemas
          el acoso escolar (bullying) - hacer novillos (to skive) - la presión de los exámenes
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *estudio, me gusta*
          2. A **time phrase** - *los lunes, el año pasado, en el futuro*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *me encanta, creo que, a mi parecer*
          5. A **second tense** - *en la primaria era..., el año que viene voy a...*

          > **A mi parecer** mi insti es genial **porque** los profesores son simpáticos.
          > **Sin embargo**, **en la primaria había** más tiempo libre.
        """)},
    ]},
    "cards": [
        card("r2-quimica", "Translate into Spanish:\n\"chemistry\"", ["la química", "química"], "Page 1 - subjects.", "La química."),
        card("r2-masque", "La informática es ____ interesante ____ el dibujo.\n(more ... than)", ["más que", "más ... que", "más...que"], "Page 2 - comparatives.", "Más interesante que."),
        card("r2-movil", "Translate into Spanish:\n\"It is forbidden to use your mobile.\"", ["está prohibido usar el móvil", "está prohibido usar el teléfono móvil", "está prohibido usar tu móvil"], "Page 3 - está prohibido + infinitive.", "Está prohibido usar el móvil."),
        mc("r2-habia", "En mi escuela primaria no ____ laboratorios.", ["había", "hay", "hubo", "habrá"], 0, "Describing the past = imperfect - page 4.", "No había laboratorios - 'there were no labs'."),
        card("r2-trompeta", "Translate into Spanish:\n\"I have been playing the trumpet for two years.\"", ["toco la trompeta desde hace dos años", "toco la trompeta desde hace 2 años", "desde hace dos años toco la trompeta"], "desde hace + present tense - page 5.", "Toco la trompeta desde hace dos años."),
        card("r2-llevar", "Translate into Spanish:\n\"We have to wear a uniform.\"", ["tenemos que llevar uniforme", "tenemos que llevar un uniforme", "hay que llevar uniforme", "hay que llevar un uniforme"], "Page 3 - tener que + infinitive.", "Tenemos que llevar uniforme."),
    ],
    "chests": [
        mc("r2-informatica", "\"la informática\" is...", ["ICT / computing", "information", "PE", "careers advice"], 0, "Page 1.", "La informática = ICT.", level=1),
        mc("r2-acoso", "\"el acoso escolar\" means...", ["bullying", "a school policy", "detention", "truancy"], 0, "Page 5.", "El acoso escolar = bullying.", level=1),
        mc("r2-novillos", "\"Mi amigo hace novillos\" means...", ["My friend skives off school", "My friend does his homework", "My friend makes friends", "My friend is new"], 0, "Page 5.", "Hacer novillos = to skive.", level=2),
        mc("r2-tancomo", "El inglés es ____ fácil ____ el francés.\n(as ... as)", ["tan / como", "más / como", "tan / que", "tanto / que"], 0, "Page 2.", "Tan fácil como - as easy as.", level=2),
        mc("r2-son", "Las ciencias ____ más difíciles que el dibujo.", ["son", "es", "están", "eran"], 0, "Plural subject, general truth.", "Las ciencias son más difíciles.", level=3),
        mc("r2-gane", "El año pasado ____ un premio de música.", ["gané", "ganaba", "gano", "ganaré"], 0, "El año pasado + one finished event = preterite.", "Gané un premio.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [30.0, 0.84], "question": "Describe tu instituto.", "tense": "present",
         "topic_words": SCHOOL_WORDS, "stars_needed": 3,
         "chips": ["mi instituto es", "hay", "me encanta", "porque", "sin embargo", "el año pasado", "era"]},
        {"kind": "postcard", "at": [135.0, 0.84], "question": "¿Cómo era tu escuela primaria?", "tense": "imperfect",
         "topic_words": SCHOOL_WORDS + ["primaria", "había", "habia", "jugaba", "jugábamos", "jugabamos"], "stars_needed": 3},
        {"kind": "postcard", "at": [310.0, 0.84], "question": "Describe una visita escolar reciente.", "tense": "preterite",
         "topic_words": SCHOOL_WORDS + ["fuimos", "fui", "museo", "autocar", "visitamos"], "stars_needed": 4},
        {"kind": "notice", "at": [195.0, 0.85], "intro": "Someone scribbled on the school notice! Write each word in the right form to fix it.",
         "text": "Mi amiga es {1} a su móvil. En el instituto {2} fotos de todo el mundo y {3} música durante el recreo. "
                 "Nunca quiere hablar con nosotros y no tiene tiempo para {4} o hacer otras cosas. "
                 "La semana pasada lo {5} en el autobús y nosotros {6} que ir a la comisaría.",
         "hint": "Does the adjective agree with 'mi amiga'? Which verbs are about last week?",
         "gaps": [
             {"verb": "adicto", "answers": ["adicta"]},
             {"verb": "sacar", "answers": ["saca"]},
             {"verb": "descargar", "answers": ["descarga"]},
             {"verb": "leer", "answers": ["leer"]},
             {"verb": "perder", "answers": ["perdió"]},
             {"verb": "tener", "answers": ["tuvimos"]},
         ]},
        {"kind": "detective", "at": [345.0, 0.8], "sign": "Foro de institutos", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Lina", "bubble": "¡Mi insti es genial!", "character": "character-female-e",
              "review": "# Lina (Madrid)\n\nMi instituto es grande, mixto y tiene muy buena fama, dado que los alumnos siempre sacan buenas notas. No hay mucho acoso escolar. En junio mis amigos y yo participamos en un concurso de bandas, y los profesores de música nos ayudaron. ¡Fue genial! No tenemos que llevar uniforme porque es más cómodo llevar ropa de calle. Sin embargo, el nuevo director va a introducir normas más estrictas: ahora está prohibido llevar maquillaje. ¡Qué pesado! Pero vamos a tener un polideportivo y un gimnasio con un muro de escalada."},
             {"name": "Marcos", "bubble": "Mi insti es... regular.", "character": "character-male-c",
              "review": "# Marcos (Sevilla)\n\nMi instituto es pequeño y bastante antiguo. Tenemos que llevar uniforme - una chaqueta azul y una corbata - y lo odio porque es muy incómodo. Las normas son estrictas: está prohibido usar el móvil y hay que ser puntual. Mi profesora de ciencias es excelente porque explica bien, pero el profesor de dibujo es muy serio. El mes pasado fuimos de excursión a un museo en autocar. ¡Qué aburrido! En la primaria había más tiempo libre y jugábamos en el patio todo el día."},
         ],
         "questions": [
             mc("d1", "¿Quién menciona el uniforme?", ["Lina", "Marcos", "Los dos"], 2, "Who talks about what they wear?", "Los dos - Lina no lleva uniforme; Marcos lleva chaqueta y corbata."),
             mc("d2", "¿Quién menciona la música?", ["Lina", "Marcos", "Los dos"], 0, "Who was in a band?", "Lina - un concurso de bandas."),
             mc("d3", "¿Quién menciona una excursión?", ["Lina", "Marcos", "Los dos"], 1, "Who went to a museum?", "Marcos - fuimos de excursión a un museo."),
             mc("d4", "¿Quién menciona las normas?", ["Lina", "Marcos", "Los dos"], 2, "Look for 'prohibido'...", "Los dos - maquillaje (Lina), móvil (Marcos)."),
             mc("d5", "¿Quién menciona las instalaciones deportivas?", ["Lina", "Marcos", "Los dos"], 0, "Who mentions a gym?", "Lina - un polideportivo y un gimnasio."),
             mc("d6", "¿Quién menciona la escuela primaria?", ["Lina", "Marcos", "Los dos"], 1, "Who talks about the past with the imperfect?", "Marcos - en la primaria había más tiempo libre."),
             mc("d7", "¿Quién menciona a un buen profesor?", ["Lina", "Marcos", "Los dos"], 2, "Who says teachers helped or explained well?", "Los dos - los profesores de música (Lina) y la profesora de ciencias (Marcos)."),
         ]},
    ],
    "sweets": [
        {"id": "r2-sweet-horario", "kind": "timetable", "question": "Translate into Spanish:\n\"I have chemistry on Tuesdays.\"",
         "answers": ["tengo química los martes", "los martes tengo química", "yo tengo química los martes", "tengo la química los martes"],
         "hint": "tener + subject + los martes", "explanation": "Tengo química los martes.",
         "timetable": [["lunes", "9:00 historia", "11:00 dibujo", "13:00 química"],
                       ["martes", "9:00 informática", "11:00 química", "13:00 historia"],
                       ["miércoles", "9:00 dibujo", "11:00 historia", "13:00 informática"]],
         "rounds": [{"say": "Es martes. Son las once.", "answer": "química"},
                    {"say": "Es lunes. Son las nueve.", "answer": "historia"},
                    {"say": "Es miércoles. Es la una.", "answer": "informática"}]},
        {"id": "r2-sweet-uniforme", "kind": "headteacher", "question": "¿Estás a favor o en contra del uniforme escolar?",
         "sentence": {"question": "La directora asks: ¿Estás a favor o en contra del uniforme escolar?", "tense": "present",
                      "topic_words": SCHOOL_WORDS + ["favor", "contra", "llevar", "ropa", "chaqueta", "corbata", "falda", "cómodo", "comodo"],
                      "stars_needed": 3}},
        {"id": "r2-sweet-estudiar", "kind": "newstudent", "question": "¿Qué te gustaría estudiar el año próximo?",
         "sentence": {"question": "El alumno nuevo asks: ¿Qué te gustaría estudiar el año próximo?", "tense": "conditional",
                      "topic_words": SCHOOL_WORDS + ["me gustaría", "me gustaria", "estudiaría", "estudiaria", "año próximo", "futuro"],
                      "stars_needed": 3}},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Sobresaliente! You conquered Isla 2."},
}

FAMILY_WORDS = ["familia", "padre", "madre", "padres", "herman", "abuel", "prim", "tío", "tio", "tía", "tia", "hijo", "hija",
                "padrastro", "madrastra", "amig", "llevo", "llevamos", "discut", "pele", "apoy", "comprensiv", "casa", "juntos"]
TECH_WORDS = ["móvil", "movil", "ordenador", "portátil", "portatil", "tableta", "internet", "red social", "redes sociales",
              "aplicaci", "app", "mensaje", "chate", "foto", "vídeo", "video", "subí", "subi", "mandé", "mande", "descargu",
              "instagram", "tiktok", "whatsapp", "youtube", "juegos", "series", "música", "musica", "pantalla", "tecnolog"]

familia = {
    "format": "lesson-island/1",
    "title": "Familia y tecnología",
    "subject": "IGCSE - Módulo 3",
    "intro": "Family, friends, phones and social media - plus how to text in Spanish.",
    "whiteboard": {"pages": [
        {"title": "Mi familia", "markdown": md("""
          # Mi familia
          En mi familia **somos** cuatro. **Vivo con** mi madre, mi padrastro y mi hermanastro.
          **Tengo** una hermana mayor / un hermano menor. **Soy** hijo único / hija única.
          Mi abuela **se llama** Carmen. **Tiene** setenta años.

          - Mi padre **es** alto, **tiene** el pelo corto y **lleva** gafas.
          - Mi madre **es** muy comprensiva y graciosa.
          - Mis primos **viven** en Argentina.

          > **ser** for character (es simpático), **tener** for age and hair (tiene el pelo rubio).
        """)},
        {"title": "Relaciones", "markdown": md("""
          # ¿Te llevas bien con tu familia?
          **Me llevo bien / mal con** mi hermano **porque**...
          **Nos llevamos** muy bien. **Nos apoyamos** en todo.
          **Discuto** con mi hermana **porque** siempre usa mi portátil.
          **Nos peleamos** a veces. Mis padres son **estrictos / comprensivos**.

          # Un buen amigo
          **Un buen amigo es alguien que** te escucha / te apoya / es leal / te hace reír.
          **Mi mejor amiga es** muy graciosa y **nos conocemos desde hace** diez años.
        """)},
        {"title": "La tecnología", "markdown": md("""
          # ¿Qué aplicaciones usas?
          **Uso** mi móvil **para** chatear con mis amigos / ver mis series favoritas /
          contactar con mi familia / subir fotos / buscar y descargar música.

          **Es** útil, práctica, rápida, fácil de usar, gratis...
          **Es** una pérdida de tiempo. **Te engancha.**
          **Lo único malo es que** roba horas al sueño.
          **Estoy enganchado/a a** mi móvil. **Soy adicto/a a** los videojuegos.
        """)},
        {"title": "¿Qué estás haciendo?", "markdown": md("""
          # Estoy + gerund - what you are doing *right now*
          -ar → **-ando**: escuch**ando**, esper**ando**, descans**ando**
          -er / -ir → **-iendo**: com**iendo**, escrib**iendo**, hac**iendo**
          irregular: **leyendo**, **durmiendo**

          - **Estoy viendo** una peli. - **Está escuchando** música.

          # ¡Vamos a quedar!
          **¿Quieres salir conmigo?** - Sí, vale / ¡Claro! / **No puedo porque tengo que**...
          **¿A qué hora quedamos?** - **A las** siete.
          **¿Dónde quedamos?** - **Delante del** cine / **al lado de** la plaza / **enfrente de** mi casa.
        """)},
        {"title": "Los peligros", "markdown": md("""
          # Los peligros de internet
          el ciberacoso (cyberbullying) - la adicción - perder horas de sueño
          lo que publicas **se escapa para siempre**

          **Hay que** tener cuidado. **Se debe** proteger tu información.
          **No se debe** hablar con desconocidos.

          # Antes y ahora
          **En el pasado**, la gente no **tenía** móviles y **escribía** cartas.
          **Hoy en día**, casi todos los jóvenes **usan** las redes sociales.
          **Ayer mandé** diez mensajes y **subí** dos fotos.
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *vivo, me llevo, uso*
          2. A **time phrase** - *hoy en día, ayer, a veces*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *creo que, lo único malo es que*
          5. A **second tense** - *ayer subí..., de pequeño tenía..., el fin de semana voy a...*

          > **Me llevo bien** con mi madre **porque** es comprensiva. **Sin embargo**,
          > **ayer discutí** con mi hermano **porque** usó mi portátil.
        """)},
    ]},
    "cards": [
        card("r3-llevo", "Translate into Spanish:\n\"I get on well with my sister.\"", ["me llevo bien con mi hermana", "yo me llevo bien con mi hermana"], "Page 2 - llevarse bien con.", "Me llevo bien con mi hermana."),
        card("r3-escuchando", "Estoy ____ música.\n(escuchar - \"listening\")", ["escuchando"], "-ar verbs: -ando - page 4.", "Estoy escuchando música."),
        mc("r3-mande", "Ayer ____ diez mensajes a mis amigos.", ["mandé", "mando", "mandaba", "mandaré"], 0, "Ayer + a finished action = preterite - page 5.", "Mandé - I sent."),
        card("r3-nopuedo", "Translate into Spanish:\n\"I can't because I have to do my homework.\"", ["no puedo porque tengo que hacer los deberes", "no puedo porque tengo que hacer mis deberes"], "Page 4 - No puedo porque tengo que...", "No puedo porque tengo que hacer los deberes."),
        card("r3-uso", "Translate into Spanish:\n\"I use my mobile to chat with my friends.\"", ["uso mi móvil para chatear con mis amigos", "uso el móvil para chatear con mis amigos", "uso mi móvil para chatear con mis amigas"], "Page 3 - uso... para...", "Uso mi móvil para chatear con mis amigos."),
        mc("r3-leyendo", "Mi hermano está ____ un libro.", ["leyendo", "leendo", "leiendo", "lee"], 0, "An irregular gerund - page 4.", "Leyendo - the i becomes y."),
    ],
    "chests": [
        mc("r3-enganchado", "\"Estoy enganchado a mi móvil\" means...", ["I'm hooked on my phone", "My phone is broken", "I'm charging my phone", "I've lost my phone"], 0, "Page 3.", "Enganchado = hooked.", level=1),
        mc("r3-perdida", "\"una pérdida de tiempo\" is...", ["a waste of time", "a lost property office", "a long time", "a time zone"], 0, "Page 3.", "Una pérdida de tiempo = a waste of time.", level=1),
        mc("r3-quedamos", "\"¿Dónde quedamos?\" means...", ["Where shall we meet?", "Where do we live?", "Where are we staying?", "Where is it?"], 0, "Page 4.", "Quedar = to arrange to meet.", level=2),
        mc("r3-enfrente", "\"enfrente de la estación\" means...", ["opposite the station", "inside the station", "behind the station", "far from the station"], 0, "Page 4.", "Enfrente de = opposite.", level=2),
        mc("r3-tenia", "En el pasado, la gente no ____ móviles.", ["tenía", "tuvo", "tiene", "tendrá"], 0, "Describing how things were = imperfect - page 5.", "No tenía móviles.", level=3),
        mc("r3-vere", "Si tengo tiempo el fin de semana, ____ una película.", ["veré", "vi", "veía", "vería"], 0, "Si + present, then the future.", "Si tengo tiempo, veré una película.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [30.0, 0.84], "question": "Describe a tu familia.", "tense": "present",
         "topic_words": FAMILY_WORDS, "stars_needed": 3,
         "chips": ["en mi familia somos", "vivo con", "me llevo bien con", "porque", "sin embargo", "ayer", "discutí"]},
        {"kind": "postcard", "at": [135.0, 0.84], "question": "¿Cómo usaste la tecnología ayer?", "tense": "preterite",
         "topic_words": TECH_WORDS, "stars_needed": 3},
        {"kind": "postcard", "at": [310.0, 0.84], "question": "¿Qué vas a hacer este fin de semana con tus amigos o tu familia?", "tense": "future",
         "topic_words": FAMILY_WORDS + TECH_WORDS + ["fin de semana", "cine", "salir", "quedar", "partido", "compras", "parque"], "stars_needed": 4},
        {"kind": "notice", "at": [195.0, 0.85], "intro": "Someone hacked the notice board! Write each verb in the right form to fix it.",
         "text": "En el pasado, la gente no {1} teléfonos móviles y {2} cartas. Hoy en día, casi todos los jóvenes {3} "
                 "las redes sociales diariamente. Ayer yo {4} diez mensajes a mis amigos y {5} dos fotos. "
                 "Si {6} tiempo el fin de semana, {7} una película en línea.",
         "hint": "En el pasado = imperfect. Hoy en día = present. Ayer = preterite. Si + present... then future.",
         "gaps": [
             {"verb": "tener", "answers": ["tenía"]},
             {"verb": "escribir", "answers": ["escribía"]},
             {"verb": "usar", "answers": ["usan"]},
             {"verb": "mandar", "answers": ["mandé"]},
             {"verb": "subir", "answers": ["subí"]},
             {"verb": "tener", "answers": ["tengo"]},
             {"verb": "ver", "answers": ["veré", "voy a ver"]},
         ]},
        {"kind": "detective", "at": [345.0, 0.8], "sign": "Redes sociales", "greeting": "¿Quién lo publicó?",
         "speakers": [
             {"name": "Carmen", "bubble": "@carmen_mola", "character": "character-female-b",
              "review": "# @carmen_mola\n\nMi familia es un poco caótica, ¡jaja! Vivo con mi madre, mi padrastro y mis dos hermanastros. Me llevo bien con mi madre porque es muy comprensiva, pero discuto mucho con mi hermanastro mayor porque siempre usa mi portátil sin permiso. ¡Qué rollo! Ayer subí fotos del cumpleaños de mi abuela. Lo único malo de las redes sociales es que te enganchan: anoche solo dormí cinco horas."},
             {"name": "Pablo", "bubble": "@pablito_07", "character": "character-male-f",
              "review": "# @pablito_07\n\nSoy hijo único y vivo con mis padres y mi perro, Toby. Mis padres son bastante estrictos: no puedo usar el móvil a la hora de cenar. Creo que tienen razón, porque cenar juntos es importante. Uso las redes sociales para chatear con mis primos en Argentina y para ver vídeos de fútbol. Mi mejor amigo, Dani, es muy leal y gracioso. El fin de semana que viene vamos a ir al cine juntos."},
         ],
         "questions": [
             mc("d1", "¿Quién menciona un animal?", ["Carmen", "Pablo", "Los dos"], 1, "Who has a pet?", "Pablo - su perro, Toby."),
             mc("d2", "¿Quién menciona a un abuelo o una abuela?", ["Carmen", "Pablo", "Los dos"], 0, "Look for a birthday...", "Carmen - el cumpleaños de su abuela."),
             mc("d3", "¿Quién discute con un miembro de su familia?", ["Carmen", "Pablo", "Los dos"], 0, "Who argues (discute)?", "Carmen - discute con su hermanastro."),
             mc("d4", "¿Quién habla de las normas en casa?", ["Carmen", "Pablo", "Los dos"], 1, "Who can't use their phone at dinner?", "Pablo - no puede usar el móvil a la hora de cenar."),
             mc("d5", "¿Quién menciona el sueño?", ["Carmen", "Pablo", "Los dos"], 0, "Who only slept five hours?", "Carmen - anoche solo durmió cinco horas."),
             mc("d6", "¿Quién usa las redes sociales?", ["Carmen", "Pablo", "Los dos"], 2, "Photos... and chatting with cousins...", "Los dos - Carmen sube fotos; Pablo chatea con sus primos."),
             mc("d7", "¿Quién habla de sus planes para el futuro?", ["Carmen", "Pablo", "Los dos"], 1, "Look for 'vamos a...'", "Pablo - vamos a ir al cine."),
         ]},
        {"kind": "chat", "at": [250.0, 0.72], "name": "Sofía", "character": "character-female-c", "color": "#e0569b",
         "turns": [
             {"them": ["¡Hola! ¿Qué tal?", "¿Qué estás haciendo ahora?"],
              "task": "Tell Sofía what you're doing right now: estoy + -ando / -iendo.",
              "hint": "Use estoy + a verb ending in -ando or -iendo: estoy escuchando música, estoy haciendo los deberes.",
              "need": [{"all": [r"\bestoy\b", r"\w+(ando|iendo|yendo)\b"], "reply": ["¡Qué guay!", "Yo estoy en casa, muy aburrida..."]}]},
             {"them": ["Oye, ¿quieres ir al cine conmigo esta tarde?"],
              "task": "Say yes - or say you can't and give a reason (No puedo porque...).",
              "hint": "Say 'sí, vale' / '¡claro!' - or 'no puedo porque tengo que...'.",
              "need": [{"all": [r"\bno puedo\b", r"\b(porque|ya que|tengo que)\b"], "reply": ["¡Qué rollo!", "Bueno... ¡pues vamos mañana!"]},
                       {"all": [r"\b(si|vale|claro|genial|de acuerdo|por supuesto|me encantaria|me gustaria|guay|venga|perfecto)\b"], "none": [r"\bno\b"],
                        "reply": ["¡Genial! ¡Qué bien!"]}]},
             {"them": ["¿A qué hora quedamos?"],
              "task": "Suggest a time: a las...",
              "hint": "Use 'a las' + a time: a las seis, a las siete y media, a la una.",
              "need": [{"all": [r"\ba las? (una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce|\d{1,2})\b"], "reply": ["Vale, perfecto."]}]},
             {"them": ["¿Y dónde quedamos?"],
              "task": "Say where to meet: delante de, al lado de, enfrente de...",
              "hint": "Try 'delante del cine', 'al lado de la plaza' or 'enfrente de mi casa'.",
              "need": [{"all": [r"\b(delante|detras|al lado|enfrente|cerca|en la puerta|en la entrada|en el|en la|en mi casa|en tu casa)\b"],
                        "reply": ["¡Hecho!", "Por cierto, ¿qué tal con tu familia? ¿Te llevas bien con ellos?"]}]},
             {"them": [],
              "task": "Tell her how you get on with your family: me llevo bien / mal con..., porque...",
              "hint": "Say 'me llevo bien con mi madre porque es comprensiva' or 'nos llevamos bien'.",
              "need": [{"all": [r"\b(me llevo|nos llevamos|se lleva|me llevo muy)\b"], "reply": ["¡Qué bien! Yo discuto mucho con mi hermano, ¡jaja!"]}]},
             {"them": ["Bueno, tengo que irme.", "¡Hasta luego!"]},
         ]},
    ],
    "sweets": [
        {"id": "r3-sweet-antenas", "kind": "towers", "question": "Translate into Spanish:\n\"The only bad thing is that it gets you hooked.\"",
         "answers": ["lo único malo es que te engancha", "lo unico malo es que te engancha"],
         "hint": "Page 3 - lo único malo es que... / te engancha", "explanation": "Lo único malo es que te engancha."},
        {"id": "r3-sweet-circuito", "kind": "circuit", "question": "Translate into Spanish:\n\"I am reading a science fiction novel.\"",
         "answers": ["estoy leyendo una novela de ciencia ficción", "estoy leyendo una novela de ciencia-ficción"],
         "hint": "estar + gerund: leer → leyendo", "explanation": "Estoy leyendo una novela de ciencia ficción."},
        {"id": "r3-sweet-familia", "kind": "grandma", "question": "¿Por qué es importante pasar tiempo en familia?",
         "sentence": {"question": "La abuela asks: ¿Por qué es importante pasar tiempo en familia?", "tense": "present",
                      "topic_words": FAMILY_WORDS + ["tiempo", "importante", "hablar", "cenar", "comer"], "stars_needed": 3}},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Conectado! You conquered Isla 3."},
}

FREE_WORDS = ["tiempo libre", "pasatiempo", "juego", "jugu", "jugar", "jugaba", "toco", "toqu", "tocar", "leo", "leer", "leí",
              "novela", "música", "musica", "concierto", "festival", "cine", "película", "pelicula", "peli", "serie",
              "deporte", "fútbol", "futbol", "baloncesto", "natación", "natacion", "nadar", "bailar", "cantar", "guitarra",
              "piano", "batería", "bateria", "videojuego", "salir", "amig", "teatro", "entrada", "grupo", "cantante", "escucho",
              "escuchar", "equipo", "partido", "gimnasio", "montar", "patinar", "dibujar", "pintar", "ocio", "descansar",
              "relajar", "fui", "vi", "suelo", "solía", "solia"]

festival = {
    "format": "lesson-island/1",
    "title": "El tiempo libre",
    "subject": "IGCSE - Módulo 4",
    "intro": "Hobbies, music, films and sport - what you do now, what you used to do, and what you're going to do.",
    "whiteboard": {"pages": [
        {"title": "Pasatiempos", "markdown": md("""
          # ¿Qué haces en tu tiempo libre?
          **Juego al** fútbol / al baloncesto / a los videojuegos (games and sports)
          **Toco** la guitarra / el piano / la batería (instruments)
          **Hago** natación / equitación / deporte. **Monto** en bici. **Leo** novelas.

          - **Me gusta** + infinitive: me gusta **bailar**.
          - **Me chifla / me mola / me flipa** la música en directo.
          - **Soy aficionado/a al** baloncesto. **Soy miembro de** un club de teatro.
          - **Suelo** ir al cine los domingos. (*I usually...*)
        """)},
        {"title": "Antes y ahora", "markdown": md("""
          # ¿Qué hacías cuando eras más joven?
          The **imperfect** for what you *used to* do:
          **Cuando era pequeño/a, jugaba** al fútbol todos los sábados.
          **Solía** ver dibujos animados. **Leía** tebeos.

          **Ahora prefiero** hacer natación **porque** es más relajante.
          **Antes** era aficionado al rugby, **pero ahora** me interesa más el tenis.

          > *solía* + infinitive = I used to... - an easy second tense!
        """)},
        {"title": "Acabo de...", "markdown": md("""
          # Acabar de + infinitive = to have just...
          **Acabo de** ver una película. - *I have just seen a film.*
          **Acabamos de** volver del festival. - *We've just come back.*

          # ¿Qué acabas de hacer?
          Acabo de... jugar un partido / escuchar el nuevo disco / leer un libro
          **Llevo** dos años tocando la guitarra. - *I've been playing for two years.*
        """)},
        {"title": "Cine y música", "markdown": md("""
          # ¿Qué tipo de películas te gustan?
          las comedias, las películas de acción / de terror / de ciencia ficción / de aventuras,
          los dibujos animados, las películas románticas

          # ¿Qué tipo de música te gusta?
          el pop, el rock, el rap, el reggaeton, el jazz, la música clásica, la música electrónica

          **Me encanta** el rock **porque** es emocionante. **No aguanto** el reggaeton.
          **Mi cantante favorito/a es**... **porque** su voz es increíble.
        """)},
        {"title": "El fin de semana", "markdown": md("""
          # El fin de semana pasado (preterite)
          **Fui** a un concierto. **Vi** una película. **Jugué** un partido. **Me divertí** mucho.
          El mes pasado **fui** a un concierto de música clásica y **fue** increíble.

          # El fin de semana que viene (future)
          **Voy a** comprar entradas para el teatro. **Iré** a un festival.
          **Mañana compraré** las entradas.
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *juego, toco, me gusta*
          2. A **time phrase** - *los fines de semana, a menudo, el sábado pasado*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *me chifla, lo mejor es, creo que*
          5. A **second tense** - *de pequeño jugaba..., el sábado que viene voy a...*

          > **Los fines de semana toco** la guitarra **porque me chifla** la música.
          > **Sin embargo**, **de pequeño jugaba** al fútbol.
        """)},
    ]},
    "cards": [
        card("r4-guitarra", "Translate into Spanish:\n\"I play the guitar.\"", ["toco la guitarra", "yo toco la guitarra"], "Instruments use tocar - page 1.", "Toco la guitarra."),
        card("r4-futbol", "Translate into Spanish:\n\"I play football.\"", ["juego al fútbol", "yo juego al fútbol", "juego fútbol"], "Sports use jugar a - page 1.", "Juego al fútbol."),
        mc("r4-jugaba", "Cuando era pequeño, ____ al baloncesto.", ["jugaba", "jugué", "juego", "jugaré"], 0, "'Used to' = imperfect - page 2.", "Jugaba - I used to play."),
        card("r4-acabo", "Translate into Spanish:\n\"I have just seen a film.\"", ["acabo de ver una película", "acabo de ver una peli"], "acabar de + infinitive - page 3.", "Acabo de ver una película."),
        mc("r4-chiflan", "Me ____ las películas de terror.", ["chiflan", "chifla", "chiflo", "chiflamos"], 0, "Like gustar: plural thing = -an.", "Me chiflan las películas de terror."),
        card("r4-voyair", "El sábado que viene ____ al cine.\n(\"I'm going to go\")", ["voy a ir"], "ir a + infinitive - page 5.", "Voy a ir al cine."),
    ],
    "chests": [
        mc("r4-dibujos", "\"los dibujos animados\" are...", ["cartoons", "drawings", "animals", "comics"], 0, "Page 4.", "Los dibujos animados = cartoons.", level=1),
        mc("r4-ocio", "\"el ocio\" means...", ["leisure", "laziness", "a hobby club", "boredom"], 0, "The topic of this island!", "El ocio = leisure / free time.", level=1),
        mc("r4-suelo", "\"Suelo ir al cine los domingos\" means...", ["I usually go to the cinema on Sundays", "I went to the cinema on Sunday", "I'm going to the cinema on Sunday", "I never go to the cinema"], 0, "Page 1 - soler.", "Suelo = I usually.", level=2),
        mc("r4-aficionado", "\"Soy aficionado al baloncesto\" means...", ["I'm a basketball fan", "I'm a basketball player", "I'm bad at basketball", "I'm a basketball coach"], 0, "Page 1.", "Aficionado = fan.", level=2),
        mc("r4-fui", "El mes pasado ____ a un concierto de música clásica.", ["fui", "iba", "voy", "iré"], 0, "El mes pasado + one event = preterite.", "Fui a un concierto.", level=3),
        mc("r4-hacer", "Ahora prefiero ____ natación porque es más relajante.", ["hacer", "hago", "hice", "haciendo"], 0, "prefiero + infinitive.", "Prefiero hacer natación.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [30.0, 0.84], "question": "¿Qué haces normalmente en tu tiempo libre?", "tense": "present",
         "topic_words": FREE_WORDS, "stars_needed": 3,
         "chips": ["en mi tiempo libre", "juego al", "toco", "me chifla", "porque", "sin embargo", "de pequeño jugaba"]},
        {"kind": "postcard", "at": [135.0, 0.84], "question": "¿Qué te gustaba hacer cuando eras más joven?", "tense": "imperfect",
         "topic_words": FREE_WORDS + ["pequeño", "pequeña", "joven", "dibujos"], "stars_needed": 3},
        {"kind": "postcard", "at": [310.0, 0.84], "question": "Describe una visita reciente al cine o a un concierto.", "tense": "preterite",
         "topic_words": FREE_WORDS + ["fuimos", "vimos", "tocaron", "cantó", "canto"], "stars_needed": 4},
        {"kind": "notice", "at": [195.0, 0.85], "intro": "The festival poster got rained on! Write each verb in the right form to fix it.",
         "text": "Cuando era joven, {1} al fútbol todos los sábados. Ahora prefiero {2} natación porque es más relajante. "
                 "El mes pasado {3} a un concierto de música clásica y {4} increíble. Mañana {5} entradas para el teatro.",
         "hint": "Cuando era joven = imperfect. prefiero + infinitive. El mes pasado = preterite. Mañana = future.",
         "gaps": [
             {"verb": "jugar", "answers": ["jugaba"]},
             {"verb": "hacer", "answers": ["hacer"]},
             {"verb": "ir", "answers": ["fui"]},
             {"verb": "ser", "answers": ["fue"]},
             {"verb": "comprar", "answers": ["compraré", "voy a comprar"]},
         ]},
        {"kind": "detective", "at": [345.0, 0.8], "sign": "Críticas", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Lucía", "bubble": "¡Me chifla la música en directo!", "character": "character-female-a",
              "review": "# Lucía (Burgos)\n\n¡Me chifla la música en directo! El verano pasado fui al festival Sonorama con mis amigas. Acampamos allí durante tres días. Aunque llovió mucho, el ambiente era fabuloso y los grupos tocaron genial. Lo mejor fue bailar delante del escenario. Lo peor: ¡las colas para los baños! El año que viene voy a volver."},
             {"name": "Andrés", "bubble": "Prefiero quedarme en casa.", "character": "character-male-e",
              "review": "# Andrés (Valencia)\n\nNormalmente no me gustan los festivales porque hay demasiada gente. Prefiero quedarme en casa y jugar a los videojuegos o leer novelas de misterio. Sin embargo, el mes pasado fui a un concierto de música clásica con mi abuelo y me encantó. Las entradas eran caras - cincuenta euros - pero valió la pena. Suelo ir al cine los domingos con mi hermana."},
         ],
         "questions": [
             mc("d1", "¿Quién menciona el tiempo?", ["Lucía", "Andrés", "Los dos"], 0, "Who mentions the rain?", "Lucía - llovió mucho."),
             mc("d2", "¿Quién menciona el precio?", ["Lucía", "Andrés", "Los dos"], 1, "Who mentions euros?", "Andrés - las entradas eran caras."),
             mc("d3", "¿Quién escuchó música en directo?", ["Lucía", "Andrés", "Los dos"], 2, "A festival... and a concert...", "Los dos - el festival (Lucía) y el concierto (Andrés)."),
             mc("d4", "¿Quién menciona a un miembro de su familia?", ["Lucía", "Andrés", "Los dos"], 1, "A grandfather and a sister...", "Andrés - su abuelo y su hermana."),
             mc("d5", "¿Quién habla del futuro?", ["Lucía", "Andrés", "Los dos"], 0, "Look for 'voy a...'", "Lucía - el año que viene voy a volver."),
             mc("d6", "¿Quién menciona la lectura?", ["Lucía", "Andrés", "Los dos"], 1, "Who reads mystery novels?", "Andrés - leer novelas de misterio."),
             mc("d7", "¿Quién durmió fuera de casa?", ["Lucía", "Andrés", "Los dos"], 0, "Acampar = to camp...", "Lucía - acamparon durante tres días."),
         ]},
        {"kind": "chat", "at": [262.0, 0.72], "name": "Marcos", "character": "character-male-b", "color": "#ff8a3c",
         "turns": [
             {"them": ["¡Hola! ¿Qué tal?", "Oye, ¿qué haces normalmente en tu tiempo libre?"],
              "task": "Tell Marcos what you usually do: juego al..., toco..., me gusta...",
              "hint": "Use the present: juego al fútbol, toco la guitarra, me gusta leer, veo series...",
              "need": [{"all": [r"\b(juego|toco|leo|veo|hago|salgo|escucho|practico|voy|monto|nado|bailo|canto|dibujo|me gusta|me encanta|me chifla|me mola|suelo)\b"],
                        "reply": ["¡Qué guay! Yo toco la batería en un grupo."]}]},
             {"them": ["¿Y qué hiciste el fin de semana pasado?"],
              "task": "Say what you did last weekend - use the preterite (fui, jugué, vi...).",
              "hint": "Use the preterite: fui al cine, jugué al fútbol, vi una peli, salí con mis amigos.",
              "need": [{"all": [r"\b(fui|fuimos|jugue|jugamos|vi|vimos|hice|hicimos|sali|salimos|toque|lei|escuche|compre|visite|comi|practique|monte|nade|baile|cante|gane|perdi|pase|estuve|me diverti|me quede|descanse|juge)\b"],
                        "reply": ["¡Qué bien!", "Yo fui a un concierto de rock. ¡Fue increíble!"]}]},
             {"them": ["Por cierto, ¿qué tipo de música te gusta?"],
              "task": "Give your opinion of a kind of music: me gusta el pop, no aguanto el rap...",
              "hint": "Say 'me encanta el rock' or 'no me gusta el reggaeton' - an opinion + a type of music.",
              "need": [{"all": [r"\b(me gusta|me gustan|me encanta|me encantan|me chifla|me mola|prefiero|odio|no aguanto|no me gusta|me flipa)\b",
                                r"\b(pop|rock|rap|reggaeton|jazz|clasica|electronica|hip hop|hip-hop|flamenco|musica|trap|indie|metal|k-pop|kpop|salsa|cancion|canciones)\b"],
                        "reply": ["¡A mí también me gusta!"]}]},
             {"them": ["¿Quieres venir al festival el sábado? ¡Toca mi grupo!"],
              "task": "Say yes - or say you can't and give a reason.",
              "hint": "Say 'sí, vale' / '¡claro!' - or 'no puedo porque tengo que...'.",
              "need": [{"all": [r"\bno puedo\b", r"\b(porque|ya que|tengo que)\b"], "reply": ["¡Qué pena! Te mando un vídeo."]},
                       {"all": [r"\b(si|vale|claro|genial|de acuerdo|por supuesto|me encantaria|me gustaria|guay|venga|perfecto)\b"], "none": [r"\bno\b"],
                        "reply": ["¡Genial! ¡Nos vemos allí!"]}]},
             {"them": ["Bueno, me voy a ensayar.", "¡Chao!"]},
         ]},
    ],
    "sweets": [
        {"id": "r4-sweet-musica", "kind": "rhythm", "question": "¿Qué tipo de música te gusta? ¿Por qué?", "at": [90.0, 0.8],
         "sign": "¡Festival!",
         "sentence": {"question": "El DJ asks: ¿Qué tipo de música te gusta? ¿Por qué?", "tense": "present",
                      "topic_words": FREE_WORDS + ["pop", "rock", "rap", "reggaeton", "jazz", "clásica", "clasica", "electrónica", "electronica", "canción", "cancion", "voz", "ritmo"],
                      "stars_needed": 3}},
        {"id": "r4-sweet-noria", "kind": "ferris", "question": "Translate into Spanish:\n\"I used to play football.\"", "at": [225.0, 0.73],
         "answers": ["solía jugar al fútbol", "jugaba al fútbol", "yo jugaba al fútbol", "yo solía jugar al fútbol", "solía jugar fútbol", "jugaba fútbol"],
         "hint": "Page 2 - solía + infinitive, or the imperfect.", "explanation": "Solía jugar al fútbol / Jugaba al fútbol."},
        {"id": "r4-sweet-descansar", "kind": "musician", "question": "¿Qué vas a hacer el fin de semana que viene para descansar?",
         "sentence": {"question": "El músico asks: ¿Qué vas a hacer el fin de semana que viene para descansar?", "tense": "future",
                      "topic_words": FREE_WORDS + ["fin de semana", "dormir", "tranquil"], "stars_needed": 3}},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Bravo! You conquered Isla 4."},
}

TOWN_WORDS = ["ciudad", "pueblo", "aldea", "barrio", "región", "region", "hay", "se puede", "museo", "parque", "plaza",
              "iglesia", "tienda", "centro comercial", "cine", "playa", "montaña", "montana", "río", "rio", "puerto",
              "estación", "estacion", "turist", "histór", "histor", "tranquil", "ruidos", "bonit", "industrial", "calle",
              "castillo", "mercado", "restaurante", "polideportivo", "biblioteca", "ayuntamiento", "vivo", "compras", "costa"]

ciudad = {
    "format": "lesson-island/1",
    "title": "La ciudad",
    "subject": "IGCSE - Módulo 5",
    "intro": "Towns, directions and shopping - how to describe where you live, find your way, and spend your money.",
    "whiteboard": {"pages": [
        {"title": "Mi ciudad", "markdown": md("""
          # ¿Dónde vives?
          **Vivo en** una ciudad / un pueblo / una aldea / un barrio tranquilo.
          **Está situado/a en** el norte / el sur / el este / el oeste de Inglaterra.
          **Está cerca de** la costa / **al lado de** las montañas / **a orillas del** río.

          **Es** histórico/a, turístico/a, industrial, pintoresco/a, ruidoso/a, tranquilo/a.
          > **estar** for location (está en el sur), **ser** for description (es bonito).
        """)},
        {"title": "¿Qué hay?", "markdown": md("""
          # ¿Qué hay en tu ciudad?
          **Hay** un museo, un polideportivo, un centro comercial, un castillo,
          una iglesia, una plaza, un mercado, muchas tiendas...
          **No hay** cine. **No hay nada para los jóvenes.** ¡Qué rollo!

          # ¿Qué se puede hacer?
          **Se puede** + infinitive: se puede **visitar** el castillo, **ir** de compras,
          **pasear** por el parque. **Se pueden** ver monumentos.
        """)},
        {"title": "¿Por dónde se va?", "markdown": md("""
          # Directions
          **Sigue todo recto.** - Go straight on.
          **Toma la primera / segunda / tercera calle a la derecha / a la izquierda.**
          **Gira** a la derecha. **Cruza** la plaza. **Está al final de la calle.**

          # Where is it?
          **al lado de** (next to) - **enfrente de** (opposite) - **delante de** (in front of)
          **detrás de** (behind) - **entre** la farmacia **y** el banco (between)
          > de + el = **del**: al lado **del** banco.
        """)},
        {"title": "De compras", "markdown": md("""
          # En el mercado
          **Quisiera / ¿Me pone...?** un kilo de naranjas, una barra de pan,
          un cartón de leche, media docena de huevos, doscientos gramos de queso.
          **¿Cuánto cuesta?** (one thing) - **¿Cuánto cuestan?** (more than one)
          **Cuesta** 1,80 €. **Cuestan** 2,50 €. (*un euro con ochenta*)
          **¿Algo más?** - **Nada más, gracias.** - **Es demasiado caro.**

          # En la tienda de ropa
          ¿Me lo puedo probar? - Es demasiado grande / pequeño. - Quisiera devolverlo.
        """)},
        {"title": "Antes y después", "markdown": md("""
          # Antes (imperfect)
          **Antes había** una fábrica. **No había** mucho turismo. **Era** más tranquilo.

          # Ahora (present)
          Ahora **vienen** muchos visitantes cada año.

          # En el futuro (future)
          El ayuntamiento **construirá** un centro comercial. **Habrá** un nuevo parque.
          **Será** más moderno. Este fin de semana **iré** al mercado.
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *vivo, hay, se puede*
          2. A **time phrase** - *los sábados, antes, en el futuro*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *me encanta, lo mejor es, creo que*
          5. A **second tense** - *antes había..., el fin de semana iré...*

          > **Vivo en** un pueblo pintoresco **porque** mis padres trabajan aquí.
          > **Lo mejor es** la playa. **Sin embargo, antes había** más tiendas.
        """)},
    ]},
    "cards": [
        card("r5-recto", "Translate into Spanish:\n\"Go straight on.\"", ["sigue todo recto", "siga todo recto", "sigue recto", "todo recto"], "Page 3 - directions.", "Sigue todo recto."),
        card("r5-segunda", "Translate into Spanish:\n\"Take the second street on the left.\"", ["toma la segunda calle a la izquierda", "tome la segunda calle a la izquierda", "coge la segunda calle a la izquierda"], "Page 3.", "Toma la segunda calle a la izquierda."),
        mc("r5-entre", "El banco está ____ la farmacia y el cine.", ["entre", "delante", "al lado", "enfrente"], 0, "Between X and Y - page 3.", "Entre la farmacia y el cine."),
        card("r5-cuestan", "¿Cuánto ____ las manzanas?\n(costar - \"do they cost\")", ["cuestan"], "More than one thing - page 4.", "¿Cuánto cuestan las manzanas?"),
        mc("r5-habia", "En el pasado no ____ mucho turismo en mi pueblo.", ["había", "hay", "habrá", "haya"], 0, "Describing the past = imperfect - page 5.", "No había mucho turismo."),
        card("r5-sepuede", "Translate into Spanish:\n\"In my town you can visit the museum.\"", ["en mi ciudad se puede visitar el museo", "en mi pueblo se puede visitar el museo", "se puede visitar el museo en mi ciudad", "se puede visitar el museo en mi pueblo"], "se puede + infinitive - page 2.", "En mi ciudad se puede visitar el museo."),
    ],
    "chests": [
        mc("r5-ayuntamiento", "\"el ayuntamiento\" is...", ["the town hall", "the shopping centre", "the sports centre", "the town square"], 0, "Page 5.", "El ayuntamiento = the town hall.", level=1),
        mc("r5-aldea", "\"una aldea\" is...", ["a small village", "a city", "a street", "a district"], 0, "Page 1.", "Una aldea = a small village.", level=1),
        mc("r5-mepone", "\"¿Me pone un kilo de tomates?\" means...", ["Can I have a kilo of tomatoes?", "Where are the tomatoes?", "How much are the tomatoes?", "Put the tomatoes down"], 0, "Page 4.", "¿Me pone...? = Can I have...?", level=2),
        mc("r5-caro", "\"Es demasiado caro\" means...", ["It's too expensive", "It's very cheap", "It's too big", "It's not for sale"], 0, "Page 4.", "Demasiado caro = too expensive.", level=2),
        mc("r5-construira", "En el futuro, el ayuntamiento ____ un centro comercial.", ["construirá", "construyó", "construía", "construye"], 0, "En el futuro = future tense - page 5.", "Construirá - it will build.", level=3),
        mc("r5-esta", "Mi pueblo ____ situado en el sur de España.", ["está", "es", "hay", "tiene"], 0, "Location = estar - page 1.", "Está situado en el sur.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [20.0, 0.84], "question": "Describe tu ciudad o tu pueblo.", "tense": "present",
         "topic_words": TOWN_WORDS, "stars_needed": 3,
         "chips": ["vivo en", "está situado en", "hay", "se puede", "porque", "sin embargo", "antes había"]},
        {"kind": "postcard", "at": [170.0, 0.8], "question": "¿Cómo era tu ciudad o tu pueblo en el pasado?", "tense": "imperfect",
         "topic_words": TOWN_WORDS + ["antes", "había", "habia", "era", "pasado"], "stars_needed": 3},
        {"kind": "postcard", "at": [300.0, 0.84], "question": "¿Qué harás este fin de semana en tu ciudad?", "tense": "future",
         "topic_words": TOWN_WORDS + ["fin de semana", "iré", "ire", "visitaré", "visitare", "compraré", "comprare"], "stars_needed": 4},
        {"kind": "notice", "at": [200.0, 0.85], "intro": "The tourist sign has been vandalised! Write each verb in the right form to fix it.",
         "text": "Mi pueblo {1} situado en el sur de España. {2} un lugar histórico y muy pintoresco. En el pasado, no {3} "
                 "mucho turismo, pero ahora muchos visitantes {4} cada año. En el futuro, el ayuntamiento {5} un nuevo centro comercial.",
         "hint": "Location = estar. Description = ser. En el pasado = imperfect. Ahora = present. En el futuro = future.",
         "gaps": [
             {"verb": "estar", "answers": ["está"]},
             {"verb": "ser", "answers": ["Es", "es"]},
             {"verb": "haber", "answers": ["había"]},
             {"verb": "venir", "answers": ["vienen"]},
             {"verb": "construir", "answers": ["construirá", "va a construir"]},
         ]},
        {"kind": "detective", "at": [240.0, 0.8], "sign": "¿Campo o ciudad?", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Elena", "bubble": "Vivo en el campo.", "character": "character-female-c",
              "review": "# Elena (Asturias)\n\nVivo en una aldea pequeña en las montañas de Asturias. Es muy tranquila y el aire es limpio, pero no hay mucho que hacer para los jóvenes: no hay cine ni centro comercial. El autobús a la ciudad solo pasa dos veces al día. Antes había una escuela, pero la cerraron. En el futuro me gustaría vivir en la costa."},
             {"name": "Javier", "bubble": "¡Me encanta Madrid!", "character": "character-male-f",
              "review": "# Javier (Madrid)\n\nVivo en el centro de Madrid. Me encanta porque hay muchísimas cosas que hacer: museos, parques, tiendas y restaurantes. El transporte público es excelente - el metro es rápido y barato. Sin embargo, hay mucha contaminación y mucho ruido, sobre todo por la noche. El sábado pasado fui de compras a la Gran Vía y gasté demasiado dinero."},
         ],
         "questions": [
             mc("d1", "¿Quién menciona el transporte?", ["Elena", "Javier", "Los dos"], 2, "A bus... and the metro...", "Los dos - el autobús (Elena) y el metro (Javier)."),
             mc("d2", "¿Quién vive en el campo?", ["Elena", "Javier", "Los dos"], 0, "Mountains, a small village...", "Elena - una aldea en las montañas."),
             mc("d3", "¿Quién menciona el aire o la contaminación?", ["Elena", "Javier", "Los dos"], 2, "Clean air... pollution...", "Los dos - el aire limpio (Elena), la contaminación (Javier)."),
             mc("d4", "¿Quién habla de ir de compras?", ["Elena", "Javier", "Los dos"], 1, "Who spent too much money?", "Javier - fue de compras a la Gran Vía."),
             mc("d5", "¿Quién menciona un colegio?", ["Elena", "Javier", "Los dos"], 0, "Una escuela...", "Elena - antes había una escuela."),
             mc("d6", "¿Quién habla del futuro?", ["Elena", "Javier", "Los dos"], 0, "Look for 'me gustaría'...", "Elena - en el futuro me gustaría vivir en la costa."),
             mc("d7", "¿Quién se queja del ruido?", ["Elena", "Javier", "Los dos"], 1, "Especially at night...", "Javier - mucho ruido, sobre todo por la noche."),
         ]},
        {"kind": "chat", "at": [345.0, 0.8], "name": "Lucas", "character": "character-male-c", "color": "#2e86de",
         "turns": [
             {"them": ["¡Hola! Voy a visitar tu ciudad el mes que viene.", "¿Qué hay allí?"],
              "task": "Tell Lucas what there is in your town: hay..., se puede...",
              "hint": "Use 'hay' + places (hay un museo, hay muchas tiendas) or 'se puede' + infinitive.",
              "need": [{"all": [r"\b(hay|se puede|se pueden|tiene|tenemos)\b"], "reply": ["¡Qué guay!"]}]},
             {"them": ["¿Y cómo llego a tu casa desde la estación?"],
              "task": "Give him directions: sigue todo recto, toma la primera calle a la derecha...",
              "hint": "Use a direction verb (sigue, toma, gira, cruza) and a direction (recto, a la derecha, a la izquierda).",
              "need": [{"all": [r"\b(sigue|siga|toma|tome|coge|gira|gire|cruza|cruce|ve|baja|sube|pasa)\b", r"\b(recto|derecha|izquierda|final)\b"],
                        "reply": ["Vale, ¡lo apunto!"]}]},
             {"them": ["¿Qué tiempo hace allí en verano?"],
              "task": "Describe the weather: hace calor, llueve, hace sol...",
              "hint": "Use 'hace' (hace calor, hace sol, hace buen tiempo) or 'llueve' / 'nieva'.",
              "need": [{"all": [r"\b(hace|llueve|nieva|esta nublado|hay niebla|hay sol|hay tormentas?|hay viento)\b"], "reply": ["¡Perfecto! Llevo mi gorra."]}]},
             {"them": ["Oye, ¿vamos de compras juntos el sábado?"],
              "task": "Say yes - or say you can't and give a reason.",
              "hint": "Say 'sí, vale' / '¡claro!' - or 'no puedo porque tengo que...'.",
              "need": [{"all": [r"\bno puedo\b", r"\b(porque|ya que|tengo que)\b"], "reply": ["¡Qué pena! Vamos otro día."]},
                       {"all": [r"\b(si|vale|claro|genial|de acuerdo|por supuesto|me encantaria|me gustaria|guay|venga|perfecto)\b"], "none": [r"\bno\b"],
                        "reply": ["¡Genial! Quiero comprar recuerdos."]}]},
             {"them": ["¡Hasta pronto!"]},
         ]},
    ],
    "sweets": [
        {"id": "r5-sweet-ferry", "kind": "ferry", "at": [80.0], "question": "Translate into Spanish:\n\"The ferry leaves at ten o'clock.\"",
         "answers": ["el ferry sale a las diez", "el ferry sale a las 10", "el barco sale a las diez", "el ferry sale a las diez en punto"],
         "hint": "salir (to leave) - sale; a las + time.", "explanation": "El ferry sale a las diez."},
        {"id": "r5-sweet-guia", "kind": "directions", "at": [120.0, 0.8], "question": "¿Qué hay para los turistas en tu barrio?",
         "character": "character-female-b",
         "greeting": "¡Hola! ¡Habla conmigo!",
         "rounds": [
             {"say": "Sigue todo recto y toma la primera calle a la derecha. El regalo está al final de la calle, al lado del banco.", "box": "A"},
             {"say": "Sigue todo recto y toma la segunda calle a la izquierda. El regalo está al final de la calle, entre la panadería y la iglesia.", "box": "D"},
             {"say": "Toma la segunda calle a la derecha. El regalo está al final de la calle, entre el cine y el museo.", "box": "C"},
         ],
         "sentence": {"question": "La guía asks: ¿Qué hay para los turistas en tu barrio?", "tense": "present",
                      "topic_words": TOWN_WORDS + ["turistas", "visitar", "monumento"], "stars_needed": 3}},
        {"id": "r5-sweet-mercado", "kind": "market", "at": [45.0, 0.8], "question": "Translate into Spanish:\n\"How much are the oranges?\"",
         "answers": ["¿cuánto cuestan las naranjas?", "cuánto cuestan las naranjas", "cuanto cuestan las naranjas"],
         "hint": "Page 4 - more than one thing: cuestan.", "explanation": "¿Cuánto cuestan las naranjas?",
         "budget": 6.0,
         "stalls": [
             {"name": "Frutería", "need": "un kilo de naranjas", "items": [
                 {"name": "naranjas", "price": 1.80, "model": "food/orange", "scale": 5.0},
                 {"name": "naranjas de Valencia", "price": 2.90, "model": "food/orange", "scale": 6.5}]},
             {"name": "Panadería", "need": "una barra de pan", "items": [
                 {"name": "pan de pueblo", "price": 2.20, "model": "food/loaf-round", "scale": 2.2},
                 {"name": "barra de pan", "price": 0.90, "model": "food/loaf-baguette", "scale": 2.4}]},
             {"name": "Lechería", "need": "un cartón de leche", "items": [
                 {"name": "leche", "price": 1.10, "model": "food/carton", "scale": 2.6},
                 {"name": "leche ecológica", "price": 1.90, "model": "food/carton-small", "scale": 3.4}]},
             {"name": "Huevos", "need": "media docena de huevos", "items": [
                 {"name": "huevos camperos", "price": 2.70, "model": "food/egg", "scale": 6.0},
                 {"name": "huevos", "price": 1.60, "model": "food/egg", "scale": 5.0}]},
         ]},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Bienvenido a la ciudad! You conquered Isla 5."},
}

FOOD_WORDS = ["comer", "como", "comí", "comi", "comemos", "beber", "bebo", "bebí", "bebi", "desayun", "almuerz", "almorz",
              "ceno", "cena", "merienda", "comida", "fruta", "verdura", "carne", "pescado", "pollo", "pizza", "hamburguesa",
              "patatas", "ensalada", "tortilla", "paella", "chocolate", "churros", "tarta", "pastel", "helado", "zumo",
              "agua", "leche", "café", "cafe", "té", "queso", "pan", "restaurante", "sano", "sana", "dieta", "vegetarian",
              "fiesta", "festival", "cumpleaños", "cumpleanos", "celebr", "navidad", "tomatina", "fuegos", "rico", "delicios"]

fiesta = {
    "format": "lesson-island/1",
    "title": "La fiesta",
    "subject": "IGCSE - Módulo 6",
    "intro": "Food, restaurants, feeling ill, and Spain's famous festivals - ¡a comer y a celebrar!",
    "whiteboard": {"pages": [
        {"title": "La comida", "markdown": md("""
          # ¿Qué comes?
          **el desayuno** (breakfast) - **el almuerzo / la comida** (lunch) - **la merienda** (snack) - **la cena** (dinner)
          **Desayuno** tostadas con mermelada. **Bebo** un zumo de naranja.
          **Me encanta** el pescado. **No aguanto** las verduras. **Soy vegetariano/a.**

          la carne, el pollo, el pescado, las patatas fritas, la ensalada, la fruta,
          el queso, los huevos, el pan, el helado, la tarta, los churros con chocolate
        """)},
        {"title": "En el restaurante", "markdown": md("""
          # ¿Qué va a tomar?
          **De primero**, la sopa. **De segundo**, el pescado. **De postre**, un helado.
          **Para mí**, la hamburguesa, por favor. **Quisiera** un café con leche.
          **¿Me trae** la cuenta, por favor?

          # ¡Hay un problema!
          La sopa **está fría**. El tenedor **está sucio**. **Falta** un cuchillo.
          **Pedí** pescado, no pollo.
        """)},
        {"title": "¿Qué te pasa?", "markdown": md("""
          # Estoy enfermo/a
          **Me duele** la cabeza / el estómago / la garganta. (one thing)
          **Me duelen** los ojos / los pies. (more than one)
          **Tengo** fiebre / tos / gripe / catarro. **Estoy** cansado/a.

          # Consejos
          **Hay que** beber mucha agua. **Debes** descansar.
          **Para llevar una vida sana**, como cinco raciones de fruta y verdura al día.
        """)},
        {"title": "Las fiestas", "markdown": md("""
          # Las fiestas de España
          **La Tomatina** se celebra en Buñol en agosto: la gente **se tira** tomates.
          **La Aste Nagusia** es la Semana Grande de Bilbao: fuegos artificiales y conciertos.
          **San Fermín** en Pamplona. **Las Fallas** en Valencia.
          **En Nochevieja** comemos doce uvas. **El Día de los Muertos** se celebra en México.

          **Se celebra** en... - **Dura** una semana. - **Hay** desfiles, música y baile.
        """)},
        {"title": "Mi cumpleaños", "markdown": md("""
          # ¿Cómo celebraste tu cumpleaños?
          **Celebré** mi cumpleaños con mi familia. **Comimos** tarta. **Soplé** las velas.
          **Recibí** muchos regalos. **Fue** un día inolvidable.

          # ¿Cómo vas a celebrar tu próximo cumpleaños?
          **Voy a** hacer una fiesta. **Invitaré** a mis amigos. **Iremos** a un restaurante.
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *como, bebo, me gusta*
          2. A **time phrase** - *normalmente, ayer, el año que viene*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *me chifla, está riquísimo, creo que*
          5. A **second tense** - *ayer comí..., mañana cenaré...*

          > **Normalmente desayuno** cereales **porque** es rápido. **Sin embargo**,
          > **ayer comí** churros con chocolate. **¡Qué rico!**
        """)},
    ]},
    "cards": [
        card("r6-cabeza", "Translate into Spanish:\n\"I have a headache.\"", ["me duele la cabeza", "tengo dolor de cabeza"], "Page 3 - me duele...", "Me duele la cabeza."),
        mc("r6-duelen", "Me ____ los ojos.", ["duelen", "duele", "duelo", "dolemos"], 0, "Plural thing that hurts - page 3.", "Me duelen los ojos."),
        card("r6-pescado", "Translate into Spanish:\n\"For me, the fish, please.\"", ["para mí el pescado por favor", "para mí, el pescado, por favor", "el pescado para mí por favor"], "Page 2 - para mí...", "Para mí, el pescado, por favor."),
        mc("r6-comi", "Ayer ____ churros con chocolate.", ["comí", "como", "comía", "comeré"], 0, "Ayer = preterite.", "Comí churros con chocolate."),
        card("r6-cuenta", "Translate into Spanish:\n\"Can you bring me the bill, please?\"", ["¿me trae la cuenta, por favor?", "me trae la cuenta por favor", "la cuenta por favor", "¿me puede traer la cuenta?"], "Page 2.", "¿Me trae la cuenta, por favor?"),
        card("r6-celebrar", "Translate into Spanish:\n\"I am going to celebrate my birthday.\"", ["voy a celebrar mi cumpleaños"], "ir a + infinitive - page 5.", "Voy a celebrar mi cumpleaños."),
    ],
    "chests": [
        mc("r6-cena", "\"la cena\" is...", ["dinner", "lunch", "breakfast", "a snack"], 0, "Page 1.", "La cena = dinner.", level=1),
        mc("r6-postre", "\"de postre\" means...", ["for dessert", "for the starter", "to drink", "to take away"], 0, "Page 2.", "De postre = for dessert.", level=1),
        mc("r6-fiebre", "\"Tengo fiebre\" means...", ["I have a temperature", "I have a cough", "I'm hungry", "I'm tired"], 0, "Page 3.", "Fiebre = a temperature / fever.", level=2),
        mc("r6-fuegos", "\"los fuegos artificiales\" are...", ["fireworks", "bonfires", "artificial flowers", "firefighters"], 0, "Page 4.", "Los fuegos artificiales = fireworks.", level=2),
        mc("r6-cenare", "Mañana ____ en un restaurante mexicano.", ["cenaré", "cené", "cenaba", "ceno"], 0, "Mañana = future.", "Cenaré - I will have dinner.", level=3),
        mc("r6-secelebra", "La Tomatina ____ en Buñol cada año.", ["se celebra", "se celebran", "celebramos", "celebran"], 0, "One festival: se celebra - page 4.", "La Tomatina se celebra en Buñol.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [20.0, 0.84], "question": "¿Qué te gusta comer y beber? ¿Por qué?", "tense": "present",
         "topic_words": FOOD_WORDS, "stars_needed": 3,
         "chips": ["me encanta", "normalmente", "desayuno", "porque", "sin embargo", "ayer comí", "es muy sano"]},
        {"kind": "postcard", "at": [150.0, 0.75], "question": "Describe una fiesta o un festival al que fuiste.", "tense": "preterite",
         "topic_words": FOOD_WORDS + ["fui", "fuimos", "vi", "bailé", "baile", "desfile", "música", "musica"], "stars_needed": 3},
        {"kind": "postcard", "at": [340.0, 0.84], "question": "¿Qué harás para llevar una vida más sana en el futuro?", "tense": "future",
         "topic_words": FOOD_WORDS + ["ejercicio", "deporte", "dormir", "beberé", "bebere", "comeré", "comere", "haré", "hare"], "stars_needed": 4},
        {"kind": "notice", "at": [175.0, 0.85], "intro": "Someone spilt chocolate on the menu board! Write each verb in the right form to fix it.",
         "text": "Normalmente {1} tostadas con mermelada y {2} un vaso de zumo de naranja. Sin embargo, ayer {3} churros "
                 "con chocolate porque {4} el cumpleaños de mi madre. Mañana {5} en un restaurante mexicano.",
         "hint": "Normalmente = present. Ayer = preterite (but 'it was her birthday' is background). Mañana = future.",
         "gaps": [
             {"verb": "desayunar", "answers": ["desayuno"]},
             {"verb": "beber", "answers": ["bebo"]},
             {"verb": "comer", "answers": ["comí"]},
             {"verb": "ser", "answers": ["era", "fue"]},
             {"verb": "cenar", "answers": ["cenaré", "voy a cenar"]},
         ]},
        {"kind": "detective", "at": [130.0, 0.8], "sign": "Las fiestas", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Ane", "bubble": "¡Aupa Bilbao!", "character": "character-female-b",
              "review": "# Ane (Bilbao)\n\nTodos los años en agosto voy a la Aste Nagusia, la Semana Grande de Bilbao. Las fiestas duran nueve días. El primer día, una mujer sale al balcón y empieza la fiesta. Por la noche hay fuegos artificiales y conciertos gratis en la calle. Lo mejor es la comida: hay pintxos por todas partes. ¡Qué rico!"},
             {"name": "Pablo", "bubble": "¡Qué locura!", "character": "character-male-d",
              "review": "# Pablo (Valencia)\n\nEl año pasado fui a la Tomatina en Buñol, cerca de Valencia. Es una fiesta muy corta - dura solo una hora - pero ¡qué locura! Miles de personas se tiran tomates en la calle. Llevé gafas de natación y una camiseta vieja. Después, los vecinos nos limpiaron con mangueras. El año que viene quiero ir otra vez con mis primos."},
         ],
         "questions": [
             mc("d1", "¿Quién menciona la música?", ["Ane", "Pablo", "Los dos"], 0, "Concerts...", "Ane - conciertos gratis en la calle."),
             mc("d2", "¿Quién habla de una fiesta muy corta?", ["Ane", "Pablo", "Los dos"], 1, "Only one hour...", "Pablo - dura solo una hora."),
             mc("d3", "¿Quién menciona algo que se puede comer?", ["Ane", "Pablo", "Los dos"], 2, "Pintxos... tomatoes...", "Los dos - pintxos (Ane) y tomates (Pablo)."),
             mc("d4", "¿Quién habla del futuro?", ["Ane", "Pablo", "Los dos"], 1, "Look for 'el año que viene'.", "Pablo - quiere ir otra vez."),
             mc("d5", "¿Quién menciona la ropa?", ["Ane", "Pablo", "Los dos"], 1, "Goggles and an old T-shirt...", "Pablo - gafas de natación y una camiseta vieja."),
             mc("d6", "¿Quién menciona los fuegos artificiales?", ["Ane", "Pablo", "Los dos"], 0, "At night...", "Ane - por la noche hay fuegos artificiales."),
             mc("d7", "¿Quién habla de una fiesta de nueve días?", ["Ane", "Pablo", "Los dos"], 0, "La Semana Grande...", "Ane - las fiestas duran nueve días."),
         ]},
        {"kind": "chat", "at": [280.0, 0.7], "name": "Carla", "character": "character-female-a", "color": "#ff5e7e",
         "turns": [
             {"them": ["¡Hola! Te vi en la Tomatina. ¡Qué divertido!", "¿Qué comiste en la fiesta?"],
              "task": "Say what you ate or drank - use the preterite (comí, bebí, probé...).",
              "hint": "Use the preterite: comí paella, bebí un zumo, probé los churros.",
              "need": [{"all": [r"\b(comi|bebi|probe|tome|comimos|bebimos|probamos|tomamos|cene|desayune|almorce)\b"], "reply": ["¡Mmm, qué rico!"]}]},
             {"them": ["Oye, el sábado es mi cumpleaños. ¿Vienes a mi fiesta?"],
              "task": "Say yes - or say you can't and give a reason (maybe you're ill: me duele...).",
              "hint": "Say 'sí, vale' / '¡claro!' - or 'no puedo porque me duele la cabeza / tengo que...'.",
              "need": [{"all": [r"\bno puedo\b", r"\b(porque|ya que|tengo que|me duele|me duelen|estoy)\b"], "reply": ["¡Qué pena! ¡Que te mejores!"]},
                       {"all": [r"\b(si|vale|claro|genial|de acuerdo|por supuesto|me encantaria|me gustaria|guay|venga|perfecto)\b"], "none": [r"\bno\b"],
                        "reply": ["¡Genial! ¡Qué ilusión!"]}]},
             {"them": ["¿Qué te gusta comer en una fiesta?"],
              "task": "Give an opinion about some food: me encanta la pizza, no me gusta...",
              "hint": "An opinion (me gusta, me encanta, prefiero...) + a food (la tarta, la pizza, los churros...).",
              "need": [{"all": [r"\b(me gusta|me gustan|me encanta|me encantan|prefiero|me chifla|me chiflan|odio|no me gusta|no me gustan|no aguanto)\b",
                                r"\b(pizza|tarta|pastel|chocolate|patatas|helado|helados|fruta|churros|tortilla|paella|hamburguesas?|bocadillos?|caramelos|dulces|pollo|pescado|queso|jamon|galletas|sandwich|nachos|palomitas|comida)\b"],
                        "reply": ["¡A mí también!"]}]},
             {"them": ["¿Y cómo celebras tu cumpleaños normalmente?"],
              "task": "Say what you normally do on your birthday - use the present.",
              "hint": "Use the present: normalmente hago una fiesta, salgo con mis amigos, como tarta...",
              "need": [{"all": [r"\b(celebro|hago|salgo|como|invito|voy|vamos|comemos|celebramos|suelo|abro|recibo|tengo|juego|bailo|ceno|cenamos)\b"],
                        "reply": ["¡Qué bien!"]}]},
             {"them": ["¡Hasta el sábado!"]},
         ]},
    ],
    "sweets": [
        {"id": "r6-sweet-restaurante", "kind": "restaurant", "at": [60.0, 0.76], "fishing_at": [100.0],
         "question": "Describe la última vez que comiste en un restaurante.",
         "chef_says": "¡Hoy no hay pescado!\n¡Pesca uno en el mar!",
         "dishes": [
             {"id": "burger", "model": "food/burger", "scale": 2.6},
             {"id": "pizza", "model": "food/pizza", "scale": 1.8},
             {"id": "icecream", "model": "food/ice-cream", "scale": 2.6},
             {"id": "fries", "model": "food/fries", "scale": 2.6},
             {"id": "coffee", "model": "food/cup-coffee", "scale": 2.6},
             {"id": "cake", "model": "food/cake", "scale": 1.3},
             {"id": "hotdog", "model": "food/hot-dog", "scale": 2.4},
         ],
         "orders": [
             {"say": "Para mí, el pescado, por favor.", "want": "fish", "character": "character-female-a"},
             {"say": "Tengo mucha hambre. Quisiera una hamburguesa.", "want": "burger", "character": "character-male-b"},
             {"say": "De postre, un helado, por favor.", "want": "icecream", "character": "character-female-d"},
         ],
         "sentence": {"question": "El cocinero asks: Describe la última vez que comiste en un restaurante.", "tense": "preterite",
                      "topic_words": FOOD_WORDS + ["pedí", "pedi", "camarero", "cuenta", "menú", "menu"], "stars_needed": 3}},
        {"id": "r6-sweet-tomatina", "kind": "tomatina", "at": [215.0, 0.8],
         "question": "Translate into Spanish:\n\"Last year I went to a festival.\"",
         "answers": ["el año pasado fui a un festival", "fui a un festival el año pasado", "el año pasado fui a una fiesta"],
         "hint": "el año pasado + preterite of ir.", "explanation": "El año pasado fui a un festival."},
        {"id": "r6-sweet-pinata", "kind": "pinata", "at": [300.0, 0.66], "question": "¿Cómo vas a celebrar tu próximo cumpleaños?",
         "sentence": {"question": "La piñata asks: ¿Cómo vas a celebrar tu próximo cumpleaños?", "tense": "future",
                      "topic_words": FOOD_WORDS + ["regalos", "amigos", "familia", "invitaré", "invitare", "fiesta"], "stars_needed": 3}},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Qué fiesta! You conquered Isla 6."},
}

WORK_WORDS = ["trabaj", "empleo", "empresa", "oficina", "sueldo", "dinero", "ganar", "jefe", "jefa", "colega", "compañer",
              "médico", "medico", "enfermer", "profesor", "abogad", "ingenier", "cocinero", "mecánico", "mecanico", "periodista",
              "veterinari", "policía", "policia", "bombero", "peluquer", "dependient", "camarer", "carrera", "universidad",
              "estudiar", "voluntari", "año sabático", "ano sabatico", "futuro", "experiencia", "prácticas", "practicas",
              "ayudar", "gente", "niños", "ninos", "animales", "viajar", "extranjero", "idiomas", "equipo", "horario"]

trabajo = {
    "format": "lesson-island/1",
    "title": "El trabajo",
    "subject": "IGCSE - Módulo 7",
    "intro": "Jobs, work experience, job interviews and your plans for the future.",
    "whiteboard": {"pages": [
        {"title": "Los trabajos", "markdown": md("""
          # ¿En qué trabaja?
          **Es** médico/a, enfermero/a, profesor/a, abogado/a, ingeniero/a, cocinero/a,
          mecánico/a, periodista, veterinario/a, bombero/a, peluquero/a, dependiente/a...
          > No article with jobs: **Mi madre es enfermera.** (not *una enfermera*)

          **Trabaja en** un hospital, una oficina, una tienda, un taller, al aire libre.
          **Trabaja a tiempo completo / a tiempo parcial.**
        """)},
        {"title": "Mi trabajo ideal", "markdown": md("""
          # ¿Qué te gustaría hacer en el futuro?
          **Me gustaría ser** veterinario/a **porque** me encantan los animales.
          **Quisiera trabajar** en el extranjero / con niños / al aire libre.
          **Sería** un trabajo **creativo, variado, bien pagado, estimulante**.

          # Lo más importante para mí
          **Lo más importante es** ganar mucho dinero / ayudar a la gente / tener un buen horario.
        """)},
        {"title": "Experiencia laboral", "markdown": md("""
          # ¿Has trabajado alguna vez?
          **Hice** mis prácticas laborales en una oficina. **Trabajé** en una tienda.
          **Tenía que** contestar el teléfono, archivar documentos, servir a los clientes.
          **Empezaba** a las nueve y **terminaba** a las cinco.
          **Aprendí** mucho. **Mis colegas eran** muy amables.

          > *Tenía que / empezaba* = imperfect (what it was usually like).
          > *Hice / aprendí* = preterite (the whole experience).
        """)},
        {"title": "La entrevista", "markdown": md("""
          # Preguntas de la entrevista
          **¿Por qué quieres este trabajo?** - **Quiero** este trabajo **porque** me interesa...
          **¿Cómo eres?** - **Soy** responsable, trabajador/a, puntual, paciente, creativo/a.
          **¿Qué experiencia tienes?** - **El año pasado trabajé** en...
          **¿Hablas idiomas?** - **Hablo** inglés y **un poco de** español.
          **¿Cuándo puedes empezar?** - **Puedo empezar** el lunes.
        """)},
        {"title": "El futuro", "markdown": md("""
          # ¿Cuáles son tus planes?
          **Voy a** hacer el bachillerato. **Iré** a la universidad.
          **Haré** un año sabático y **viajaré** por el mundo.
          **Trabajaré** como voluntario/a en un orfanato.
          **Si** saco buenas notas, **estudiaré** medicina. (si + present, future)
          **Espero** / **Tengo la intención de** / **Quiero** + infinitive
        """)},
        {"title": "5 estrellas", "markdown": md("""
          # How to write a 5-star answer
          1. A **verb in the right tense** - *me gustaría, trabajaré, trabajé*
          2. A **time phrase** - *en el futuro, el año pasado, después del instituto*
          3. A **connective** - *porque, sin embargo, además*
          4. An **opinion** - *lo más importante es, creo que, me encanta*
          5. A **second tense** - *el año pasado hice mis prácticas...*

          > **En el futuro me gustaría ser** periodista **porque me encanta** escribir.
          > **El año pasado hice** mis prácticas en un periódico.
        """)},
    ]},
    "cards": [
        card("r7-enfermera", "Translate into Spanish:\n\"My mother is a nurse.\"", ["mi madre es enfermera"], "No article with jobs - page 1.", "Mi madre es enfermera."),
        card("r7-gustaria", "Translate into Spanish:\n\"I would like to be a vet.\"", ["me gustaría ser veterinario", "me gustaría ser veterinaria"], "me gustaría ser... - page 2.", "Me gustaría ser veterinario/a."),
        mc("r7-hice", "El año pasado ____ mis prácticas laborales en una oficina.", ["hice", "hacía", "hago", "haré"], 0, "El año pasado + the whole experience = preterite - page 3.", "Hice mis prácticas."),
        mc("r7-tenia", "En mis prácticas ____ que contestar el teléfono.", ["tenía", "tuve", "tengo", "tendré"], 0, "What it was usually like = imperfect - page 3.", "Tenía que contestar el teléfono."),
        card("r7-ire", "Translate into Spanish:\n\"I will go to university.\"", ["iré a la universidad", "voy a ir a la universidad"], "Future of ir - page 5.", "Iré a la universidad."),
        card("r7-sisaco", "Si ____ buenas notas, estudiaré medicina.\n(sacar - \"I get\")", ["saco"], "si + present, then the future - page 5.", "Si saco buenas notas..."),
    ],
    "chests": [
        mc("r7-sueldo", "\"el sueldo\" is...", ["the salary", "the boss", "the timetable", "the job advert"], 0, "Money!", "El sueldo = the salary / pay.", level=1),
        mc("r7-parcial", "\"a tiempo parcial\" means...", ["part-time", "full-time", "overtime", "on time"], 0, "Page 1.", "A tiempo parcial = part-time.", level=1),
        mc("r7-sabatico", "\"un año sabático\" is...", ["a gap year", "a sabbath", "a school year", "a year abroad at university"], 0, "Page 5.", "Un año sabático = a gap year.", level=2),
        mc("r7-trabajador", "\"Soy trabajadora\" means...", ["I'm hard-working", "I'm a worker", "I'm working", "I work a lot of hours"], 0, "Page 4 - personality.", "Trabajador/a = hard-working.", level=2),
        mc("r7-estudiare", "Si saco buenas notas, ____ medicina.", ["estudiaré", "estudié", "estudiaba", "estudio"], 0, "si + present → future.", "Estudiaré medicina.", level=3),
        mc("r7-encantaba", "Antes ____ en un hospital, pero ahora trabajo al aire libre.", ["trabajaba", "trabajo", "trabajaré", "trabaje"], 0, "Antes = what used to happen: imperfect.", "Antes trabajaba en un hospital.", level=3),
    ],
    "retos": [
        {"kind": "postcard", "at": [20.0, 0.84], "question": "¿En qué te gustaría trabajar en el futuro? ¿Por qué?", "tense": "conditional",
         "topic_words": WORK_WORDS, "stars_needed": 3,
         "chips": ["me gustaría ser", "porque", "lo más importante es", "sin embargo", "el año pasado", "trabajé"]},
        {"kind": "postcard", "at": [150.0, 0.75], "question": "Háblame de tus prácticas laborales o de un trabajo que hiciste.", "tense": "preterite",
         "topic_words": WORK_WORDS + ["hice", "trabajé", "trabaje", "aprendí", "aprendi", "tenía que", "tenia que"], "stars_needed": 3},
        {"kind": "postcard", "at": [345.0, 0.84], "question": "¿Cuáles son tus planes para el futuro, aparte del trabajo?", "tense": "future",
         "topic_words": WORK_WORDS + ["casarme", "hijos", "casa", "viajaré", "viajare", "viviré", "vivire", "iré", "ire", "haré", "hare"], "stars_needed": 4},
        {"kind": "notice", "at": [175.0, 0.85], "intro": "The job advert has been smudged! Write each word in the right form to fix it.",
         "text": "Ahora me {1} mi trabajo porque trabajo al aire libre. Antes {2} en un hospital, pero el sueldo era muy malo. "
                 "{3} empezar a las diez de la mañana y {4} a las cuatro de la tarde. El trabajo no {5} muy difícil; tenía que "
                 "{6} el teléfono y mandar correos {7}. Me llevaba bien con mi jefe porque era muy comprensivo. {8} muchas cosas {9}.",
         "hint": "Ahora = present (me encanta...). Antes = what used to happen: imperfect. Adjectives agree!",
         "gaps": [
             {"verb": "encantar", "answers": ["encanta"]},
             {"verb": "trabajar", "answers": ["trabajaba"]},
             {"verb": "soler", "answers": ["Solía", "solía"]},
             {"verb": "terminar", "answers": ["terminaba"]},
             {"verb": "ser", "answers": ["era"]},
             {"verb": "contestar", "answers": ["contestar"]},
             {"verb": "electrónico", "answers": ["electrónicos"]},
             {"verb": "aprender", "answers": ["Aprendí", "aprendí"]},
             {"verb": "nuevo", "answers": ["nuevas"]},
         ]},
        {"kind": "detective", "at": [100.0, 0.82], "sign": "Mi primer trabajo", "greeting": "¿Quién lo dice?",
         "speakers": [
             {"name": "Rafael", "bubble": "Trabajé en una empresa.", "character": "character-male-b",
              "review": "# Rafael\n\nMi primer trabajo fue en una empresa de marketing y lo recuerdo perfectamente. Era un trabajo administrativo, así que sacaba muchas fotocopias, archivaba documentos y me encargaba de repartir el correo. No era un trabajo muy interesante, pero mis colegas eran muy amables y aprendí mucho sobre el mundo laboral."},
             {"name": "Elena", "bubble": "Trabajé en la biblioteca.", "character": "character-female-c",
              "review": "# Elena\n\nMi primera experiencia de trabajo tuvo lugar en la biblioteca de la universidad. El sueldo no era muy bueno, sin embargo, el horario era fantástico porque me permitía asistir a clase y aún tenía tiempo para estudiar. Mis tareas eran muy variadas: colocaba y organizaba los libros, estaba en la recepción dando la bienvenida a estudiantes y muchas veces ayudaba en la sala de ordenadores."},
         ],
         "questions": [
             mc("d1", "¿Quién organizaba los papeles y los documentos?", ["Rafael", "Elena", "Los dos"], 0, "Photocopies, files...", "Rafael - archivaba documentos."),
             mc("d2", "¿Quién no ganaba mucho dinero?", ["Rafael", "Elena", "Los dos"], 1, "El sueldo...", "Elena - el sueldo no era muy bueno."),
             mc("d3", "¿Quién podía trabajar y estudiar a la vez?", ["Rafael", "Elena", "Los dos"], 1, "The timetable...", "Elena - el horario le permitía asistir a clase."),
             mc("d4", "¿Quién trabajaba con gente simpática?", ["Rafael", "Elena", "Los dos"], 0, "Colleagues...", "Rafael - sus colegas eran muy amables."),
             mc("d5", "¿Quién hablaba con los alumnos de la universidad?", ["Rafael", "Elena", "Los dos"], 1, "At reception...", "Elena - daba la bienvenida a estudiantes."),
             mc("d6", "¿Quién aprendió algo de su trabajo?", ["Rafael", "Elena", "Los dos"], 0, "Look for 'aprendí'.", "Rafael - aprendió mucho sobre el mundo laboral."),
         ]},
        {"kind": "chat", "at": [255.0, 0.72], "name": "Diego", "character": "character-male-f", "color": "#f28c28",
         "turns": [
             {"them": ["¡Hola! Estoy buscando un trabajo para el verano.", "¿Tú trabajas?"],
              "task": "Say whether you work (or not) and where: trabajo en..., no trabajo pero...",
              "hint": "Use the present: trabajo en una tienda, hago de canguro, no trabajo porque...",
              "need": [{"all": [r"\b(trabajo|no trabajo|ayudo|hago de|cuido|reparto|lavo|paseo|trabajaba|trabaje)\b"], "reply": ["¡Ah, qué interesante!"]}]},
             {"them": ["¿Qué te gustaría hacer en el futuro?"],
              "task": "Say what job you'd like: me gustaría ser..., quiero ser...",
              "hint": "Use 'me gustaría ser' or 'quiero ser' + a job (médico, profesora, periodista...).",
              "need": [{"all": [r"\b(me gustaria|quiero|quisiera|espero|voy a|sere|seria|tengo la intencion de)\b"], "reply": ["¡Qué guay! Yo quiero ser bombero."]}]},
             {"them": ["¿Y qué es lo más importante para ti en un trabajo?"],
              "task": "Say what matters most: lo más importante es...",
              "hint": "Start 'Lo más importante es...' + ganar dinero / ayudar a la gente / tener buenos colegas.",
              "need": [{"all": [r"\b(lo mas importante|lo que mas|para mi|es importante|me importa|prefiero)\b"], "reply": ["Estoy de acuerdo."]}]},
             {"them": ["Oye, hay una entrevista en la oficina de empleo. ¿Vienes conmigo mañana?"],
              "task": "Say yes - or say you can't and give a reason.",
              "hint": "Say 'sí, vale' / '¡claro!' - or 'no puedo porque tengo que...'.",
              "need": [{"all": [r"\bno puedo\b", r"\b(porque|ya que|tengo que)\b"], "reply": ["¡Qué pena! ¡Deséame suerte!"]},
                       {"all": [r"\b(si|vale|claro|genial|de acuerdo|por supuesto|me encantaria|me gustaria|guay|venga|perfecto)\b"], "none": [r"\bno\b"],
                        "reply": ["¡Genial! ¡Nos vemos allí!"]}]},
             {"them": ["¡Hasta mañana!"]},
         ]},
    ],
    "sweets": [
        {"id": "r7-sweet-entrevista", "kind": "interview", "at": [300.0, 0.7], "question": "La entrevista",
         "interview": [
             {"question": "La jefa: ¿Por qué quieres este trabajo?", "tense": "present",
              "topic_words": WORK_WORDS + ["quiero", "me interesa", "me encanta", "responsable", "puntual"], "stars_needed": 3},
             {"question": "La jefa: ¿Qué experiencia tienes? Háblame de un trabajo que hiciste.", "tense": "preterite",
              "topic_words": WORK_WORDS + ["hice", "trabajé", "trabaje", "ayudé", "ayude"], "stars_needed": 3},
             {"question": "La jefa: ¿Dónde te ves dentro de diez años?", "tense": "future",
              "topic_words": WORK_WORDS + ["viviré", "vivire", "seré", "sere", "tendré", "tendre", "diez años", "diez anos"], "stars_needed": 3},
         ]},
        {"id": "r7-sweet-cinta", "kind": "sorter", "at": [60.0, 0.76], "need": 6,
         "question": "Translate into Spanish:\n\"I would like to work abroad.\"",
         "answers": ["me gustaría trabajar en el extranjero", "quisiera trabajar en el extranjero", "me gustaria trabajar en el extranjero"],
         "hint": "Page 2 - me gustaría + infinitive; abroad = en el extranjero.", "explanation": "Me gustaría trabajar en el extranjero.",
         "jobs": [
             {"job": "médico", "items": [["un botiquín", "proc/firstaid", 3.0], ["una mascarilla", "proc/mask", 3.5]]},
             {"job": "cocinero", "items": [["una sartén", "proc/pan", 3.0], ["unos huevos", "food/egg", 5.0]]},
             {"job": "profesor", "items": [["unos libros", "furniture/books", 8.0], ["una pizarra", "proc/chalkboard", 3.0]]},
             {"job": "mecánico", "items": [["una llave inglesa", "proc/wrench", 3.0], ["una rueda", "proc/tyre", 3.0]]},
         ]},
        {"id": "r7-sweet-grua", "kind": "crane", "at": [215.0, 0.78], "question": "Translate into Spanish:\n\"I am going to take a gap year.\"",
         "answers": ["voy a hacer un año sabático", "haré un año sabático", "voy a tomar un año sabático"],
         "hint": "Page 5 - ir a + hacer; a gap year = un año sabático.", "explanation": "Voy a hacer un año sabático."},
    ],
    "prize": {"name": "Estrella de Oro", "message": "¡Estás contratado! You conquered Isla 7."},
}

os.makedirs(OUT, exist_ok=True)
with open(os.path.join(OUT, "01_vacaciones.json"), "w", encoding="utf-8") as f:
    json.dump(vacaciones, f, ensure_ascii=False, indent=2)
print("01_vacaciones.json:", len(vacaciones["whiteboard"]["pages"]), "pages,", len(vacaciones["cards"]), "cards,",
      len(vacaciones["chests"]), "chests,", len(vacaciones["retos"]), "retos,", len(vacaciones["sweets"]), "sweets")
with open(os.path.join(OUT, "02_instituto.json"), "w", encoding="utf-8") as f:
    json.dump(instituto, f, ensure_ascii=False, indent=2)
print("02_instituto.json:", len(instituto["whiteboard"]["pages"]), "pages,", len(instituto["cards"]), "cards,",
      len(instituto["chests"]), "chests,", len(instituto["retos"]), "retos,", len(instituto["sweets"]), "sweets")
with open(os.path.join(OUT, "03_familia.json"), "w", encoding="utf-8") as f:
    json.dump(familia, f, ensure_ascii=False, indent=2)
print("03_familia.json:", len(familia["whiteboard"]["pages"]), "pages,", len(familia["cards"]), "cards,",
      len(familia["chests"]), "chests,", len(familia["retos"]), "retos,", len(familia["sweets"]), "sweets")
with open(os.path.join(OUT, "04_festival.json"), "w", encoding="utf-8") as f:
    json.dump(festival, f, ensure_ascii=False, indent=2)
print("04_festival.json:", len(festival["whiteboard"]["pages"]), "pages,", len(festival["cards"]), "cards,",
      len(festival["chests"]), "chests,", len(festival["retos"]), "retos,", len(festival["sweets"]), "sweets")
with open(os.path.join(OUT, "05_ciudad.json"), "w", encoding="utf-8") as f:
    json.dump(ciudad, f, ensure_ascii=False, indent=2)
print("05_ciudad.json:", len(ciudad["whiteboard"]["pages"]), "pages,", len(ciudad["cards"]), "cards,",
      len(ciudad["chests"]), "chests,", len(ciudad["retos"]), "retos,", len(ciudad["sweets"]), "sweets")
with open(os.path.join(OUT, "06_fiesta.json"), "w", encoding="utf-8") as f:
    json.dump(fiesta, f, ensure_ascii=False, indent=2)
print("06_fiesta.json:", len(fiesta["whiteboard"]["pages"]), "pages,", len(fiesta["cards"]), "cards,",
      len(fiesta["chests"]), "chests,", len(fiesta["retos"]), "retos,", len(fiesta["sweets"]), "sweets")
with open(os.path.join(OUT, "07_trabajo.json"), "w", encoding="utf-8") as f:
    json.dump(trabajo, f, ensure_ascii=False, indent=2)
print("07_trabajo.json:", len(trabajo["whiteboard"]["pages"]), "pages,", len(trabajo["cards"]), "cards,",
      len(trabajo["chests"]), "chests,", len(trabajo["retos"]), "retos,", len(trabajo["sweets"]), "sweets")
