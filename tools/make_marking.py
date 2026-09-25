"""Generates lessons/igcse/marking_es.json - the word lists the sentence builder marks with.

Verb forms are generated from a verb list (regular patterns + irregular overrides), so
every tense's forms are spelled correctly. Teachers can add phrases to the lists at the
bottom and re-run:  python tools/make_marking.py
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "lessons", "igcse", "marking_es.json")

AR = """visitar viajar nadar tomar bailar cenar comprar descansar pasar quedar alojar llegar jugar
sacar tocar hablar escuchar estudiar trabajar montar pasear alquilar cocinar disfrutar levantar
lavar duchar acostar despertar mirar ganar gastar llevar usar ayudar cambiar reservar esperar
llamar practicar empezar celebrar preparar regalar limpiar odiar encantar gustar molar mejorar
organizar participar dejar olvidar contar encontrar probar pensar recomendar bucear veranear
acampar chatear descargar navegar relajar quejar entrar terminar comenzar almorzar desayunar
explorar broncear bajar caminar andar nevar tardar costar""".split()
ER = """comer beber aprender correr vender perder conocer parecer coger volver llover responder
comprender romper meter barrer entender""".split()
IR = """vivir escribir salir decidir subir abrir dormir divertir preferir sentir pedir seguir
descubrir recibir compartir repetir servir elegir asistir""".split()

# Irregular preterite: full override (yo, tú, él, nosotros, vosotros, ellos)
PRET_IRR = {
    "ser": "fui fuiste fue fuimos fuisteis fueron", "ir": "fui fuiste fue fuimos fuisteis fueron",
    "hacer": "hice hiciste hizo hicimos hicisteis hicieron", "tener": "tuve tuviste tuvo tuvimos tuvisteis tuvieron",
    "estar": "estuve estuviste estuvo estuvimos estuvisteis estuvieron", "poder": "pude pudiste pudo pudimos pudisteis pudieron",
    "poner": "puse pusiste puso pusimos pusisteis pusieron", "querer": "quise quisiste quiso quisimos quisisteis quisieron",
    "saber": "supe supiste supo supimos supisteis supieron", "venir": "vine viniste vino vinimos vinisteis vinieron",
    "decir": "dije dijiste dijo dijimos dijisteis dijeron", "traer": "traje trajiste trajo trajimos trajisteis trajeron",
    "conducir": "conduje condujiste condujo condujimos condujisteis condujeron", "dar": "di diste dio dimos disteis dieron",
    "ver": "vi viste vio vimos visteis vieron", "leer": "leí leíste leyó leímos leísteis leyeron",
    "oír": "oí oíste oyó oímos oísteis oyeron", "dormir": "dormí dormiste durmió dormimos dormisteis durmieron",
    "pedir": "pedí pediste pidió pedimos pedisteis pidieron", "preferir": "preferí preferiste prefirió preferimos preferisteis prefirieron",
    "divertir": "divertí divertiste divirtió divertimos divertisteis divirtieron", "sentir": "sentí sentiste sintió sentimos sentisteis sintieron",
    "seguir": "seguí seguiste siguió seguimos seguisteis siguieron", "servir": "serví serviste sirvió servimos servisteis sirvieron",
    "elegir": "elegí elegiste eligió elegimos elegisteis eligieron", "repetir": "repetí repetiste repitió repetimos repetisteis repitieron",
    "haber": "hubo", "caer": "caí caíste cayó caímos caísteis cayeron", "construir": "construí construiste construyó construimos construisteis construyeron",
}
IMPF_IRR = {"ser": "era eras era éramos erais eran", "ir": "iba ibas iba íbamos ibais iban",
            "ver": "veía veías veía veíamos veíais veían", "haber": "había"}
FUT_STEM = {"tener": "tendr", "poder": "podr", "hacer": "har", "decir": "dir", "salir": "saldr",
            "venir": "vendr", "poner": "pondr", "querer": "querr", "saber": "sabr", "haber": "habr"}
PRES_IRR = {"ser": "soy eres es somos sois son", "ir": "voy vas va vamos vais van", "estar": "estoy estás está estamos estáis están",
            "tener": "tengo tienes tiene tenemos tenéis tienen", "hacer": "hago haces hace hacemos hacéis hacen",
            "poder": "puedo puedes puede podemos podéis pueden", "querer": "quiero quieres quiere queremos queréis quieren",
            "jugar": "juego juegas juega jugamos jugáis juegan", "preferir": "prefiero prefieres prefiere preferimos preferís prefieren",
            "salir": "salgo sales sale salimos salís salen", "ver": "veo ves ve vemos veis ven", "haber": "hay",
            "dormir": "duermo duermes duerme dormimos dormís duermen", "volver": "vuelvo vuelves vuelve volvemos volvéis vuelven",
            "pensar": "pienso piensas piensa pensamos pensáis piensan", "venir": "vengo vienes viene venimos venís vienen",
            "decir": "digo dices dice decimos decís dicen", "saber": "sé sabes sabe sabemos sabéis saben", "dar": "doy das da damos dais dan"}
PART_IRR = {"hacer": "hecho", "ver": "visto", "escribir": "escrito", "volver": "vuelto", "decir": "dicho", "poner": "puesto",
            "abrir": "abierto", "romper": "roto", "descubrir": "descubierto", "ir": "ido", "ser": "sido", "leer": "leído"}

ALL = AR + ER + IR + ["ser", "ir", "hacer", "tener", "estar", "poder", "poner", "querer", "saber", "venir", "decir",
                      "traer", "conducir", "dar", "ver", "leer", "haber"]


def stem(v):
    return v[:-2]


def pret_regular(v):
    s, e = stem(v), v[-2:]
    if e == "ar":
        yo = s + "é"
        if v.endswith("car"): yo = s[:-1] + "qué"
        if v.endswith("gar"): yo = s + "ué"
        if v.endswith("zar"): yo = s[:-1] + "cé"
        return [yo, s + "aste", s + "ó", s + "amos", s + "asteis", s + "aron"]
    return [s + "í", s + "iste", s + "ió", s + "imos", s + "isteis", s + "ieron"]


def impf_regular(v):
    s, e = stem(v), v[-2:]
    if e == "ar":
        return [s + x for x in ["aba", "abas", "aba", "ábamos", "abais", "aban"]]
    return [s + x for x in ["ía", "ías", "ía", "íamos", "íais", "ían"]]


def fut(v, cond=False):
    st = FUT_STEM.get(v, v)
    ends = ["ía", "ías", "ía", "íamos", "íais", "ían"] if cond else ["é", "ás", "á", "emos", "éis", "án"]
    return [st + x for x in ends]


def pres_regular(v):
    s, e = stem(v), v[-2:]
    ends = {"ar": ["o", "as", "a", "amos", "áis", "an"], "er": ["o", "es", "e", "emos", "éis", "en"],
            "ir": ["o", "es", "e", "imos", "ís", "en"]}[e]
    return [s + x for x in ends]


def participle(v):
    if v in PART_IRR: return PART_IRR[v]
    return stem(v) + ("ado" if v.endswith("ar") else "ido")


tenses = {"preterite": set(), "imperfect": set(), "future": set(), "conditional": set(), "present": set()}
infinitives = set()
participles = set()
for v in ALL:
    infinitives.add(v)
    tenses["preterite"].update(PRET_IRR[v].split() if v in PRET_IRR else pret_regular(v))
    tenses["imperfect"].update(IMPF_IRR[v].split() if v in IMPF_IRR else impf_regular(v))
    if v != "haber":
        tenses["future"].update(fut(v))
        tenses["conditional"].update(fut(v, True))
    else:
        tenses["future"].add("habrá"); tenses["conditional"].add("habría")
    tenses["present"].update(PRES_IRR[v].split() if v in PRES_IRR else pres_regular(v))
    participles.add(participle(v))
# Common reflexive/pronoun forms work because the verb itself is matched (me quedé -> quedé).
# "como" (like/as), "para" and "vino" (wine) are too ambiguous to count.
for amb in ["como", "para", "vino", "sal", "paso", "cambio", "viaje", "ayuda", "cena", "baile", "compra", "juego", "llamo"]:
    for t in tenses.values():
        t.discard(amb)

data = {
    "tenses": {k: sorted(v) for k, v in tenses.items()},
    "infinitives": sorted(infinitives),
    "participles": sorted(participles),
    "near_future_aux": ["voy a", "vas a", "va a", "vamos a", "vais a", "van a"],
    "perfect_aux": ["he", "has", "ha", "hemos", "habéis", "han"],
    "connectives": ["porque", "ya que", "dado que", "puesto que", "sin embargo", "además", "pero", "aunque", "por eso",
                    "así que", "también", "por un lado", "por otro lado", "por desgracia", "desafortunadamente",
                    "primero", "luego", "después", "más tarde", "finalmente", "entonces", "mientras", "incluso", "o sea"],
    "opinions": ["me gustó", "me encantó", "me chifló", "me flipó", "me gusta", "me encanta", "me chifla", "me mola",
                 "me apasiona", "me flipa", "odio", "odié", "prefiero", "lo mejor fue", "lo peor fue", "lo mejor es",
                 "lo peor es", "lo bueno", "lo malo", "lo pasé", "lo paso", "lo pasamos", "fue increíble", "fue inolvidable",
                 "fue genial", "fue un desastre", "fue horroroso", "fue divertido", "fue aburrido", "fue impresionante",
                 "fue flipante", "qué horror", "qué desastre", "qué guay", "qué bien", "creo que", "pienso que",
                 "en mi opinión", "para mí", "a mi parecer", "me parece", "me pareció", "estoy de acuerdo",
                 "estoy a favor", "estoy en contra", "no estoy de acuerdo", "me interesa", "lo odio", "qué pesado", "es injusto", "es justo",
                 "no me gustó", "no me gusta", "me gustaría", "me encantaría", "sería", "era increíble", "era aburrido"],
    "time_phrases": ["ayer", "anoche", "anteayer", "el año pasado", "el verano pasado", "el invierno pasado",
                     "la semana pasada", "el fin de semana pasado", "el mes pasado", "el lunes pasado", "el sábado pasado",
                     "hace", "cuando era pequeño", "cuando era pequeña", "cuando era joven", "de joven", "de pequeño",
                     "de pequeña", "normalmente", "a menudo", "siempre", "a veces", "de vez en cuando", "todos los días",
                     "el año que viene", "el próximo año", "la semana que viene", "el verano que viene", "mañana",
                     "en el futuro", "el primer día", "el último día", "al día siguiente", "por la mañana",
                     "por la tarde", "por la noche", "durante", "el año próximo",
                     "los lunes", "los martes", "los miércoles", "los jueves", "los viernes", "los fines de semana",
                     "en la primaria", "cada día", "después del insti", "después del colegio", "en el recreo", "el curso que viene"],
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=1)
print(OUT, {k: len(v) for k, v in data["tenses"].items()})
