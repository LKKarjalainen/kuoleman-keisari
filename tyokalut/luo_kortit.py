#!/usr/bin/env python3
"""Luo tavallisen korttipakan (52 korttia + 2 jokeria) SVG-kuvina kansioon kortit/.

Godotin SVG-tuonti ei piirrä <text>-elementtejä, joten kaikki numerot, kirjaimet
ja maiden symbolit muutetaan fonteista poluiksi fontToolsin avulla.

Käyttö (projektin juuresta):  python3 tyokalut/luo_kortit.py
Tiedostot:  kortit/<maa>_<arvo>.svg  (arvo 2-14, kuningas = 13, ässä = 14)
            kortit/jokeri_1.svg (punainen), kortit/jokeri_2.svg (musta)
"""

import math
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

# Sama kuvasuhde ja koko kuin korttitaka.jpg:llä, jotta kortit ja taka ovat
# pelissä saman kokoisia samalla skaalauksella (0.2).
LEVEYS, KORKEUS = 474, 709

NUMEROFONTTI = "/usr/share/fonts/google-noto/NotoSerif-Bold.ttf"
SYMBOLIFONTTI = "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf"

PUNAINEN = "#c8102e"
MUSTA = "#1a1a1a"

MAAT = {
    "hertta": ("♥", PUNAINEN),
    "ruutu": ("♦", PUNAINEN),
    "risti": ("♣", MUSTA),
    "pata": ("♠", MUSTA),
}
ARVOT = {11: "J", 12: "Q", 13: "K", 14: "A"}

# Numerokorttien kuvioiden paikat: (sarake, rivi), sarake 0/1/2 = vasen/keski/oikea,
# rivi 0..1 ylhäältä alas kuvioalueen sisällä.
KUVIOT = {
    2: [(1, 0), (1, 1)],
    3: [(1, 0), (1, 0.5), (1, 1)],
    4: [(0, 0), (2, 0), (0, 1), (2, 1)],
    5: [(0, 0), (2, 0), (1, 0.5), (0, 1), (2, 1)],
    6: [(0, 0), (2, 0), (0, 0.5), (2, 0.5), (0, 1), (2, 1)],
    7: [(0, 0), (2, 0), (1, 0.25), (0, 0.5), (2, 0.5), (0, 1), (2, 1)],
    8: [(0, 0), (2, 0), (1, 0.25), (0, 0.5), (2, 0.5), (1, 0.75), (0, 1), (2, 1)],
    9: [(0, 0), (2, 0), (0, 1 / 3), (2, 1 / 3), (1, 0.5),
        (0, 2 / 3), (2, 2 / 3), (0, 1), (2, 1)],
    10: [(0, 0), (2, 0), (1, 1 / 6), (0, 1 / 3), (2, 1 / 3),
         (0, 2 / 3), (2, 2 / 3), (1, 5 / 6), (0, 1), (2, 1)],
}
SARAKKEET = (150, LEVEYS / 2, LEVEYS - 150)
KUVIOALUE_Y = (150, KORKEUS - 150)
KUVION_KORKEUS = 82


class Fontti:
    def __init__(self, polku):
        self.font = TTFont(polku)
        self.glyfit = self.font.getGlyphSet()
        self.cmap = self.font.getBestCmap()
        self.versaali = self.font["OS/2"].sCapHeight

    def _nimi(self, merkki):
        return self.cmap[ord(merkki)]

    def rajat(self, merkki):
        pen = BoundsPen(self.glyfit)
        self.glyfit[self._nimi(merkki)].draw(pen)
        return pen.bounds

    def polku(self, merkki, skaala, x, y):
        """SVG-polku merkille, kun sen origo (perusviiva) on kohdassa (x, y)."""
        svg = SVGPathPen(self.glyfit)
        self.glyfit[self._nimi(merkki)].draw(
            TransformPen(svg, (skaala, 0, 0, -skaala, x, y)))
        return svg.getCommands()

    def symboli(self, merkki, cx, cy, korkeus):
        """Yksittäinen merkki keskitettynä (cx, cy):hyn, korkeus = merkin oma korkeus."""
        x0, y0, x1, y1 = self.rajat(merkki)
        s = korkeus / (y1 - y0)
        return self.polku(merkki, s, cx - (x0 + x1) / 2 * s, cy + (y0 + y1) / 2 * s)

    def teksti(self, teksti, cx, cy, korkeus):
        """Tekstirivi keskitettynä (cx, cy):hyn, korkeus = versaalikorkeus."""
        s = korkeus / self.versaali
        hmtx = self.font["hmtx"]
        leveys = sum(hmtx[self._nimi(m)][0] for m in teksti) * s
        x, y = cx - leveys / 2, cy + korkeus / 2
        osat = []
        for m in teksti:
            osat.append(self.polku(m, s, x, y))
            x += hmtx[self._nimi(m)][0] * s
        return " ".join(osat)


numerot = Fontti(NUMEROFONTTI)
symbolit = Fontti(SYMBOLIFONTTI)


def kaanna(sisalto):
    """Kääntää sisällön 180° kortin keskipisteen ympäri."""
    return f'<g transform="rotate(180 {LEVEYS / 2} {KORKEUS / 2})">{sisalto}</g>'


def polku(d, vari):
    return f'<path d="{d}" fill="{vari}"/>'


def kulmamerkki(arvo, maa, vari):
    """Arvo ja maa vasempaan yläkulmaan sekä käännettynä oikeaan alakulmaan."""
    x = 52
    teksti = numerot.teksti(arvo, x, 68, 50)
    # "10" on kaksi merkkiä leveä, joten kavennetaan sitä vähän
    if len(arvo) > 1:
        teksti_svg = f'<g transform="translate({x} 0) scale(0.8 1) translate({-x} 0)">{polku(teksti, vari)}</g>'
    else:
        teksti_svg = polku(teksti, vari)
    kulma = teksti_svg + polku(symbolit.symboli(maa, x, 132, 42), vari)
    return kulma + kaanna(kulma)


def pohja(sisalto):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{LEVEYS}" height="{KORKEUS}" '
        f'viewBox="0 0 {LEVEYS} {KORKEUS}">\n'
        f'<rect x="3" y="3" width="{LEVEYS - 6}" height="{KORKEUS - 6}" rx="28" '
        f'fill="#fdfdf8" stroke="#8a8a8a" stroke-width="4"/>\n'
        f'{sisalto}\n</svg>\n'
    )


def numerokortti(luku, maa, vari):
    osat = []
    ylä, ala = KUVIOALUE_Y
    for sarake, rivi in KUVIOT[luku]:
        x = SARAKKEET[sarake]
        y = ylä + rivi * (ala - ylä)
        kuvio = polku(symbolit.symboli(maa, x, y, KUVION_KORKEUS), vari)
        # Alapuoliskon kuviot ovat ylösalaisin kuten oikeissa korteissa
        if rivi > 0.5:
            kuvio = f'<g transform="rotate(180 {x} {y})">{kuvio}</g>'
        osat.append(kuvio)
    return "".join(osat)


def assa(maa, vari):
    return polku(symbolit.symboli(maa, LEVEYS / 2, KORKEUS / 2, 200), vari)


def kuvakortti(kirjain, maa, vari):
    kehys = (f'<rect x="100" y="100" width="{LEVEYS - 200}" height="{KORKEUS - 200}" '
             f'rx="12" fill="none" stroke="{vari}" stroke-width="5"/>')
    return (kehys
            + polku(numerot.teksti(kirjain, LEVEYS / 2, 265, 140), vari)
            + polku(symbolit.symboli(maa, LEVEYS / 2, 490, 100), vari))


def tahti(cx, cy, r, sakarat=5):
    pisteet = []
    for i in range(sakarat * 2):
        sade = r if i % 2 == 0 else r * 0.42
        kulma = -math.pi / 2 + i * math.pi / sakarat
        pisteet.append(f"{cx + sade * math.cos(kulma):.1f},{cy + sade * math.sin(kulma):.1f}")
    return "M" + " L".join(pisteet) + " Z"


def jokeri(vari):
    kulma = "".join(polku(numerot.teksti(k, 48, 60 + i * 50, 36), vari)
                    for i, k in enumerate("JOKER"))
    keski = (polku(tahti(LEVEYS / 2, KORKEUS / 2 - 40, 130), vari)
             + polku(numerot.teksti("JOKER", LEVEYS / 2, KORKEUS / 2 + 150, 56), vari))
    return kulma + kaanna(kulma) + keski


def main():
    kansio = Path(__file__).resolve().parent.parent / "kortit"
    kansio.mkdir(exist_ok=True)

    for maan_nimi, (maa, vari) in MAAT.items():
        for luku in range(2, 15):
            arvo = ARVOT.get(luku, str(luku))
            if luku == 14:
                keski = assa(maa, vari)
            elif luku > 10:
                keski = kuvakortti(arvo, maa, vari)
            else:
                keski = numerokortti(luku, maa, vari)
            svg = pohja(kulmamerkki(arvo, maa, vari) + keski)
            (kansio / f"{maan_nimi}_{luku}.svg").write_text(svg)

    for i, vari in enumerate((PUNAINEN, MUSTA), start=1):
        (kansio / f"jokeri_{i}.svg").write_text(pohja(jokeri(vari)))

    print(f"Luotiin 54 korttia kansioon {kansio}")


if __name__ == "__main__":
    main()
