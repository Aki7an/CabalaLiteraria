import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\aki7a\.cursor\projects\c-Users-aki7a-Documents-Godot-CifraLetra"
    r"\assets\c__Users_aki7a_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"459a8eaa5574feabc3153e5620507384_images_image5-d26a68bc-7a35-4455-9f01-4cd21da36eb8.png"
)
DST = ROOT / "data" / "images" / "image5.png"

PUZZLES = {
    "es": {
        "index": 116,
        "image_number": 5,
        "text": "El 20 de julio de 1969, Apolo 11 dejó su huella en la Luna.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong y Buzz Aldrin caminaron por la Luna ante cientos de millones de personas que lo seguían en directo. Por primera vez, el ser humano pisaba otro mundo. Sin viento que las borre, sus huellas siguen allí.",
        "category": "Efeméride",
        "language": "es",
        "difficulty": 1,
        "hint_1": "Efeméride del alunizaje del Apolo 11: la imagen señala la palabra huella.",
        "hint_2": "Palabras que están en la frase:",
        "hint_3": "",
        "Longitud frase": 36,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "en": {
        "index": 116,
        "image_number": 5,
        "text": "On July 20, 1969, Apollo 11 left its footprint on the Moon.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong and Buzz Aldrin walked on the Moon as hundreds of millions of people watched live. For the first time, humans stood on another world. With no wind to erase them, their footprints are still there.",
        "category": "Event",
        "language": "en",
        "difficulty": 1,
        "hint_1": "Apollo 11 moon landing: the image points to the word footprint.",
        "hint_2": "Words that are in the sentence:",
        "hint_3": "",
        "Longitud frase": 36,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "de": {
        "index": 116,
        "image_number": 5,
        "text": "Am 20. Juli 1969 hinterließ Apollo 11 seinen Fußabdruck auf dem Mond.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong und Buzz Aldrin betraten den Mond, während Hunderte Millionen Menschen live zusahen. Zum ersten Mal stand ein Mensch auf einer anderen Welt. Ohne Wind, der sie verweht, sind ihre Fußabdrücke noch heute dort.",
        "category": "Ereignis",
        "language": "de",
        "difficulty": 1,
        "hint_1": "Apollo-11-Mondlandung: das Bild zeigt auf das Wort Fußabdruck.",
        "hint_2": "Wörter, die im Satz stehen:",
        "hint_3": "",
        "Longitud frase": 48,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "fr": {
        "index": 116,
        "image_number": 5,
        "text": "Le 20 juillet 1969, Apollo 11 a laissé son empreinte sur la Lune.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong et Buzz Aldrin ont marché sur la Lune, suivis en direct par des centaines de millions de personnes. Pour la première fois, l'être humain foulait un autre monde. Sans vent pour les effacer, leurs empreintes sont toujours là.",
        "category": "Événement",
        "language": "fr",
        "difficulty": 1,
        "hint_1": "Alunissage d'Apollo 11 : l'image désigne le mot empreinte.",
        "hint_2": "Mots qui sont dans la phrase :",
        "hint_3": "",
        "Longitud frase": 42,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "it": {
        "index": 116,
        "image_number": 5,
        "text": "Il 20 luglio 1969 l'Apollo 11 lasciò la sua impronta sulla Luna.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong e Buzz Aldrin camminarono sulla Luna, seguiti in diretta da centinaia di milioni di persone. Per la prima volta l'essere umano calcava un altro mondo. Senza vento a cancellarle, le loro impronte sono ancora lì.",
        "category": "Evento",
        "language": "it",
        "difficulty": 1,
        "hint_1": "Allunaggio dell'Apollo 11: l'immagine indica la parola impronta.",
        "hint_2": "Parole che sono nella frase:",
        "hint_3": "",
        "Longitud frase": 44,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "pt": {
        "index": 116,
        "image_number": 5,
        "text": "Em 20 de julho de 1969, a Apollo 11 deixou a sua pegada na Lua.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong e Buzz Aldrin caminharam na Lua diante de centenas de milhões de pessoas que os viam ao vivo. Pela primeira vez, o ser humano pisava outro mundo. Sem vento que as apague, as suas pegadas continuam lá.",
        "category": "Evento",
        "language": "pt",
        "difficulty": 1,
        "hint_1": "Alunagem da Apollo 11: a imagem aponta a palavra pegada.",
        "hint_2": "Palavras que estão na frase:",
        "hint_3": "",
        "Longitud frase": 40,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
    "eu": {
        "index": 116,
        "image_number": 5,
        "text": "1969ko uztailaren 20an Apollo 11k bere aztarna utzi zuen Ilargian.",
        "letters_init": "",
        "description_init": "",
        "description_end": "Neil Armstrong eta Buzz Aldrin Ilargian ibili ziren, ehunka milioi pertsonak zuzenean ikusten zituzten bitartean. Lehen aldiz, gizakiak beste mundu bat zapaldu zuen. Haizerik ez dagoenez, haien aztarnak han daude oraindik.",
        "category": "Gertaera",
        "language": "eu",
        "difficulty": 1,
        "hint_1": "Apollo 11ren ilargiratzea: irudiak aztarna hitza seinalatzen du.",
        "hint_2": "Esaldiaren hitzak:",
        "hint_3": "",
        "Longitud frase": 46,
        "hint_4": "",
        "game_mode": "quick",
        "source": "",
        "difficulty_estimated": 0,
        "difficulty_measured": 0,
        "test_users": 0,
    },
}


def upsert(lang: str, entry: dict) -> None:
    path = ROOT / "data" / ("frases_%s.json" % lang)
    text = path.read_text(encoding="utf-8")
    if '"index": 116' in text:
        print("already has 116", path)
        return
    block = json.dumps(entry, ensure_ascii=False, indent="\t")
    block = "\t" + block.replace("\n", "\n\t")
    marker = '\t{\n\t\t"index": 10,'
    if marker not in text:
        raise SystemExit("index 10 marker not found in %s" % path)
    path.write_text(text.replace(marker, block + ",\n" + marker, 1), encoding="utf-8")
    print("inserted", path)


def main() -> None:
    if not SRC.exists():
        raise SystemExit("missing source image %s" % SRC)
    DST.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SRC, DST)
    print("copied", DST, DST.stat().st_size)
    for lang, entry in PUZZLES.items():
        upsert(lang, entry)


if __name__ == "__main__":
    main()
