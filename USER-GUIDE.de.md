# Benutzerhandbuch

So arbeitest du mit AstCDR — Anruf-Journal, Kosten, Statistik und Operator-Panel.
Dies ist die Anleitung für den Alltag aller, die AstCDR nutzen, am Ende ergänzt um die
Verwaltungsseiten; Installation und Konfiguration sind getrennt beschrieben
([INSTALL.md](INSTALL.md), [CONFIGURATION.md](CONFIGURATION.md) — beide englisch). Das
englische Original dieses Handbuchs ist [USER-GUIDE.md](USER-GUIDE.md).

Was du siehst, hängt von deinen **Rechten** ab (vergibt ein Admin über Rollen, siehe
[Benutzer & Rollen](#benutzer--rollen)) — ein Reiter oder Knopf, für den dir das Recht
fehlt, ist einfach nicht da.

Ab Werk folgt die Oberfläche der **Sprache deines Browsers**; über das Sprachmenü in der
Kopfzeile kannst du sie fest auf **Deutsch, Englisch, Spanisch oder Französisch** stellen.
Dieses Handbuch verwendet die deutschen Bezeichnungen.

---

## Ansichten

Die Kopfzeile hat einen **Ansichts-Umschalter** mit bis zu vier Ansichten:

- **Panel** — das [Operator-Panel](#operator-panel): die Telefonanlage live, und Gespräche
  bedienen (lizenzierte Version, Recht *Panel öffnen*).
- **Liste** — das Anruf-Journal.
- **Kosten** — die [Kostenanalyse](#kostenanalyse) deiner abgerechneten Gespräche (Recht
  *Kosten sehen*).
- **Statistik** — die [Anrufstatistik](#statistik): Volumen, Heatmap, Warteschlangen, pro
  Nebenstelle und mehr (Recht *Statistik*).

In Liste, Kosten und Statistik ist die **Filterzeile identisch**, und dein aktueller Filter
(Zeitraum, Ämter, Suche …) **wandert beim Umschalten mit** — einmal filtern, dreimal
hinschauen.

---

## Die Kopfzeile

- **Live** — der Schalter für die automatische Aktualisierung. Ist er an (grüner Punkt),
  aktualisiert sich das Journal alle paar Sekunden von selbst, ohne Neuladen: Zeilen,
  Kennzahlen-Karten und die Seitennavigation ziehen mit — kommt durch einen neuen Anruf eine
  Seite dazu, kannst du direkt hinspringen. **Ein Klick pausiert**: Der Punkt wird zu einem
  gelben **Pause**-Zeichen mit der Beschriftung *Pause*, und die Liste bleibt auf der
  aktuellen Ansicht stehen — praktisch, wenn neue Anrufe die Zeilen beim Lesen ständig nach
  unten schieben. Ein weiterer Klick setzt fort.
- **Sync** — der Zustand der Datenerfassung (des Ingest, der die Anrufe aus deiner
  Telefonanlage liest). Das ist eine Statusanzeige, kein Knopf:
  - 🟢 **Sync aktiv** — der Ingest ist auf dem aktuellen Stand; die Daten sind aktuell.
  - 🟡 **Sync: Aufbau** (Kreisel) — der Ingest baut den Cache (neu) auf oder holt auf
    (z. B. beim ersten Start, nach einem Cache-Neuaufbau oder nach einem Ausfall). Solange
    das läuft, kann das Journal unvollständig sein.
  - 🔴 **Sync offline** — der Ingest hat sich eine Weile nicht gemeldet; **die Daten können
    veraltet sein**. Siehe [Troubleshooting](TROUBLESHOOTING.md).
- **Sprache** (Globus) — ein Menü zur Wahl der Oberflächensprache: **Browser** (die
  Vorgabe — folgt dem `Accept-Language` deines Browsers, ersatzweise Englisch), English,
  Deutsch, Español oder Français. Wird pro Benutzer gemerkt.
- **Thema** (Mond/Sonne) — dunkel / hell / wie das Betriebssystem.
- **Tabelle maximieren** — blendet Kopfzeile, Kennzahlen und Filter aus, damit möglichst
  viele Zeilen sichtbar sind; ein schwebender Knopf (*Normalansicht*) holt sie zurück.
- **Als App installieren** (Bildschirm-Symbol) — nur, wo der Browser das anbietet, siehe
  [Tastatur, Touch und App](#tastatur-touch-und-app).
- **Einstellungen** (Zahnrad, nur mit einem Admin-Recht) — siehe [Verwaltung](#verwaltung).
- **Dein Name** — öffnet [dein Konto](#dein-konto); daneben **Abmelden**.

## Kennzahlen (KPIs)

Diese Karten fassen die aktuelle Filterauswahl zusammen und aktualisieren sich live (die
letzte erscheint nur, wenn Anrufkosten konfiguriert sind):

| Karte | Bedeutung |
|------|---------|
| **Anrufe gesamt** | Anzahl der echten Anrufe in der Auswahl. |
| **Angenommen** | Angenommene Anrufe, mit der Annahmequote in %. |
| **Verpasst** | Eingehende Anrufe, die nicht angenommen wurden (Mailbox zählt **nicht** als verpasst). |
| **Ø Klingelzeit** | Durchschnittliche Zeit bis zur Annahme. |
| **Ø Gesprächsdauer** | Durchschnittliche Gesprächslänge. |
| **Kosten** | Geschätzte Gesamtkosten der abgerechneten abgehenden Beine in der Auswahl (inkl. Anrufen, die nach extern weitergeleitet wurden). Nur sichtbar, wenn eine Tarifdatei konfiguriert ist — siehe [COSTS.md](COSTS.md). |

---

## Filtern

### Zeitraum
Nimm die **Schnellwahl** — *Heute*, *7 Tage*, *30 Tage*, *Akt. Monat*, *Letzter Monat*,
*Alle* — oder wähle mit den Datumsfeldern einen genauen Zeitraum **von/bis**.

### Suchfeld
Das Suchfeld versteht eine kleine Abfragesprache — freien Text, Feld-Operatoren und
logische Verknüpfungen. Es ist **fehlertolerant**: Lässt sich eine Abfrage nicht auswerten,
sucht es einfach nach dem Text, du bekommst also immer ein Ergebnis.

Beim Tippen wird **nicht** sofort gesucht — so wird eine längere Abfrage (`nst:50 UND
nst:51`) nie mittendrin abgeschnitten. Tipp alles ein und wende es dann mit **Enter** oder
dem **✓**-Knopf am Ende des Felds an (praktisch auf Touch-Geräten). Das **×** vor dem **?**
löscht den Suchfilter mit einem Tipp; das **?** zeigt eine kurze Syntax-Erinnerung.

**Freier Text** sucht über **alle Beteiligten** — Nummern und Namen, beide Seiten, dazu das
Amt (Teilstring, Groß-/Kleinschreibung egal):
- **`+49221`** — jede Nummer, die `+49221` enthält.
- **`Meier`** — jeder Name, der „Meier" enthält.
- **`"Meier GmbH"`** — eine Phrase in Anführungszeichen, als Ganzes gesucht.

**Feld-Operatoren** zielen auf ein Feld (jeder hat einen deutschen und einen englischen
Namen):

| Operator | Trifft |
|----------|---------|
| `nst:14` / `#14` | genau diese **Nebenstelle** (kein Teilstring) |
| `von:` / `from:` | den **Anrufer** (Nummer oder Name) |
| `an:` / `to:` | den **Angerufenen** (Nummer oder Name) |
| `amt:` / `trunk:` | das **Amt** |
| `via:` / `über:` | die **DDI / Rufnummer**, über die ein Anruf hereinkam (die Spalte *Über*). Weitere Namen: `vía:`, `ddi:`. |
| `status:` | `answered`/`ok` (auch `angenommen`), `missed` (auch `verpasst`), `voicemail` (auch `mailbox`) |
| `richtung:` / `dir:` | `inbound` (auch `kommend`), `outbound` (auch `gehend`), `internal` (auch `intern`) |
| `zone:` | die Kosten-**Zone** |
| `codec:` | Anrufe, bei denen ein Kanal diesen **Codec** nutzte — `opus`, `g722`, `pcma`/`alaw`, `pcmu`/`ulaw`, `g729` … (auch so geschrieben wie in der Anzeige, z. B. `G.722`) — oder `codec:transcoded` (auch `transkodiert`, `tc`) für Anrufe, die Asterisk **transkodiert** hat. Gleiche Regel wie in der Spalte *Codecs*: Es zählt der letzte Messwert jedes Kanals. Braucht die Codec-Erfassung (`ami:`). |

**Verknüpfen** mit logischen Operatoren:
- **UND** — Begriffe einfach nebeneinander schreiben (implizit), oder `AND` / `UND`.
- **ODER** — `OR` / `ODER`.
- **NICHT** — ein vorangestelltes `-` (`-nst:19`) oder `NOT` / `NICHT`.
- **Klammern** zum Gruppieren: `(nst:19 OR nst:21) status:missed`.

Beispiele:
- `status:missed to:+49221 -nst:19` — verpasste Anrufe an +49221…, aber nicht Nebenstelle 19.
- `von:Meier richtung:inbound` — eingehende Anrufe von einem Anrufer namens Meier.
- `(amt:telekom OR amt:easybell) status:answered` — angenommene Anrufe auf einem der beiden Ämter.
- `codec:transcoded amt:easybell` — Anrufe auf dem Amt easybell, die Asterisk transkodieren musste.
- `codec:opus -codec:transcoded` — Opus-Anrufe, die ohne Transkodierung liefen.

Die Auswahllisten und Checkboxen darunter grenzen weiter ein — sie werden mit deiner Suche
per **UND** verknüpft.

### Checkboxen
- **Nur Erfolgreiche** — angenommene Anrufe.
- **Nur Verpasste** — nicht angenommene eingehende Anrufe.
- **Nur Externe** — Anrufe mit einem externen Teilnehmer (über ein Amt).
- **Ignorierte zeigen** — zeigt Ereignisse, die sonst ausgeblendet sind (Tür/Durchsage usw.,
  konfiguriert unter `journal.hide`, dazu das reine Wählen des Kennzahl-Codes, wenn jemand
  einen Anruf **heranholt** — der eigentliche Anruf erscheint separat mit seinem
  **PU**-Merkmal).

### Nebenstellen-Auswahl
Wähle eine oder mehrere interne Nebenstellen, um nur die Anrufe zu sehen, an denen sie
beteiligt sind (per ODER verknüpft). Gleiche Wirkung wie `#<nst>` im Suchfeld.

Alle Filter stehen in der **URL**, eine gefilterte Ansicht lässt sich also teilen und als
Lesezeichen speichern.

### Gespeicherte Filter
Neben der Zeitraum-Schnellwahl kannst du in der Auswahl **Gespeicherte Filter**
Filterkombinationen ablegen, die du oft brauchst. Stell einen beliebigen Filter ein
(Zeitraum, Suche, Nebenstellen, Amt, Richtung, Checkboxen …), öffne die Auswahl, wähle
**Aktuellen Filter speichern** und gib ihm einen Namen. Er steht dann in der Liste — ein
Klick wendet ihn in jeder Ansicht an (Liste, Kosten, Statistik); das **×** neben einem
Eintrag entfernt ihn. Speicherst du einen neuen Filter unter einem vorhandenen Namen,
wird der alte überschrieben.

Gespeicherte Filter liegen **pro Benutzer** (auf dem Server, in deinen Einstellungen), sie
folgen dir also nach der Anmeldung in jeden Browser. Seitenzahl und Oberflächensprache
merken sie sich bewusst **nicht** — nur den Filter selbst. Lokale Notzugangs- und
OIDC-Benutzer haben jeweils ihren eigenen Satz; ohne Anmeldung lassen sich keine Filter
speichern.

---

## Die Tabelle

Jede Zeile ist ein logischer Anruf (alle seine Beine zusammengefaltet).

### Spalten

| Spalte | Bedeutung |
|--------|---------|
| **#** | Laufende Nummer über alle Seiten (nur zur Orientierung). |
| **Zeit** | Startzeit des Anrufs. |
| **Richtung** | kommend / gehend / intern (mit Symbol; verpasste eingehende sind markiert). |
| **Status** | Angenommen / Verpasst / Nicht angenommen / Mailbox / System, dazu Merkmale (siehe unten). |
| **Von · Nr / Von · Name / Von · Ort** | Nummer und Name des Anrufers, bei externen Nummern Land/Ort. Mit Panel und dem Recht *Wählen* sind Nummern unterstrichen: Ein Klick bietet **Diese Nummer anrufen** — das Panel öffnet sich und wählt sie von deinem Arbeitsplatz aus. Mit dem Recht *Eigene Kurzwahlen anlegen* bietet die externe Nummer eines Anrufs außerdem **Als Kurzwahl speichern**. |
| **An · Nr / An · Name / An · Ort** | Nummer, Name und Ort des Angerufenen. Bei einem **verpassten** eingehenden Anruf steht hier die Nebenstelle, die geklingelt hat — bei einem Direktanruf die eine Nebenstelle, bei einem Follow-Me die ursprünglich gewählte. Ein **Queue**-Anruf bleibt hier leer (es klingeln mehrere Nebenstellen gleichzeitig, also gibt es kein einzelnes „An"). |
| **Amt** | Das Provider-Amt (Trunk), über das der Anruf lief — die Spalte, die kommerzielle CTI-Lösungen leer lassen. |
| **Über** | Die Rufnummer, über die der Anruf hereinkam bzw. hinausging, wo relevant. |
| **Beteiligt** | Die internen Nebenstellen, die beteiligt waren. |
| **Ruf** | Zeit bis zur Annahme. |
| **Gespräch** | Gesprächsdauer. |
| **Auflegen** | Wer den Anruf beendet hat: eine interne Nebenstelle oder die externe Seite — bei eingehenden Anrufen als *Anrufer*, bei abgehenden als *Angerufener* angezeigt. |
| **Aufz.** | Ein roter Punkt, wenn es eine Aufnahme zum Anruf gibt (hohl: alle wurden gelöscht). Mit einem Aufnahme-Recht (lizenzierte Version) öffnet ein Klick die Aufnahmen des Anrufs in einer Seitenleiste — abspielen, herunterladen, löschen. |
| **Codecs** | Nur mit eingeschalteter Codec-Erfassung (siehe [CONFIGURATION.md](CONFIGURATION.md#ami--codec--media-capture-optional)): die Codecs des Anrufs, z. B. *G.722 ↔ Opus*, mit **⚠**, wenn Asterisk zwischen ihnen transkodieren musste. Details stehen in der aufgeklappten Ansicht des Anrufs. |
| **Kosten / Kosten real / Zone / Kontingent** | Geschätzte Kosten der abgerechneten **abgehenden Beine** des Anrufs — ein normaler abgehender Anruf oder ein eingehender, der nach extern weitergeleitet wurde —, sofern eine Tarifdatei konfiguriert ist (siehe [COSTS.md](COSTS.md)). *Kosten real* berücksichtigt Freiminuten; *Kontingent* sind die in diesem Monat verbleibenden Freiminuten. |

Nicht jede Spalte ist ab Werk sichtbar — siehe [Spalten auswählen](#spalten-auswählen).

### Status-Merkmale
Kleine Abzeichen neben dem Status zeigen Besonderheiten:
- **Q** (*Warteschlange*) — der Anruf lief über eine Queue.
- **FM** (*FollowMe*) — er wurde über eine Follow-Me-Regel geleitet.
- **↪** (*weitergeleitet*) — der Anruf wurde übergeben.
- **P** (*geparkt*) — der Anruf wurde geparkt.
- **PU** (*herangeholt*) — jemand hat den Anruf an einem *anderen* Telefon angenommen
  (Pickup, meist gewählt als `**<Nebenstelle>`). Die Anrufdetails nennen die Nebenstelle,
  **für** die er herangeholt wurde, und diese Nebenstelle steht unter *Beteiligt* — so
  taucht der Anruf weiterhin auf, wenn du nach der Person filterst, deren Telefon
  tatsächlich geklingelt hat.

### Sortieren
Klick auf einen **Spaltenkopf**, um danach zu sortieren. Ein weiterer Klick wechselt
zwischen auf- und absteigend. Die aktive Spalte ist mit einem Pfeil (↑/↓) markiert. Bei
Gleichstand entscheidet immer die Zeit, die Reihenfolge bleibt also stabil.

### Orte (Flaggen)
Bei externen Nummern zeigen die *Ort*-Spalten die Landesflagge und — bei Festnetznummern —
die Stadt, offline aus der Nummer abgeleitet. Du erkennst eine Flagge nicht? Am Desktop mit
der Maus darüberfahren zeigt den Ländernamen; am Handy antippen.

---

## Anrufdetails

Ein Klick auf eine Zeile klappt sie auf. Die Detailansicht zeigt:

- **Meta-Zeile:** Amt, „Über"-Nummer, Follow-Me-Ziel, Queues, Parkplatz, Gesamtdauer und,
  falls vorhanden, die Aufnahme-Markierung.
- **Aufnahmen** (lizenzierte Version, mit einem Aufnahme-Recht): jede Aufnahmedatei des
  Anrufs, mit einem Knopf, der sie in der [Aufnahme-Seitenleiste](#aufnahmen) öffnet;
  gelöschte sind als *Aufnahme gelöscht* aufgeführt, mit Angabe, wer sie wann gelöscht hat.
- **Beendigungsgrund:** warum der Anruf endete, im Klartext, sobald es etwas anderes als
  ein normales Auflegen war — z. B. *Kein Anschluss unter dieser Nummer*, *Teilnehmer
  besetzt*, *Anruf abgelehnt* (aus dem ITU-T-Q.850-Cause des Netzbetreibers). Hat der
  Anrufer noch beim Wählen aufgelegt, bevor die Gegenseite abnahm, steht dort *Wahl
  abgebrochen* — der rohe Cause des Netzbetreibers ist in diesem Moment unzuverlässig und
  würde nur in die Irre führen. Dasselbe gilt, wenn ein Telefon auflegt, bevor die Anlage
  den Anruf überhaupt geroutet hat (z. B. versehentlich gedrückte Wahlwiederholung): Ein
  solcher Anruf erscheint als *gehend* an die gewählte Nummer, ohne Amt. Mit dem Recht
  *Technische Details* siehst du zusätzlich die rohe Cause-Nummer.
- **Codecs** (mit eingeschalteter Codec-Erfassung): die Codecs und eine Markierung
  **⚠ transkodiert**. Der Knopf **Details** öffnet ein Fenster mit jedem Kanal — der
  Nebenstelle oder dem Amt, seinem Codec (**HD** bei Breitband-Codecs wie Opus oder G.722;
  **HD↓**, wenn dieses Bein zwar einen Breitband-Codec nutzt, aber nur Schmalband-Ton
  bekommt — die Gegenstelle in derselben Verbindung ist schmalbandig, z. B. PCMA vom Amt,
  auch wenn der Anruf über eine Queue, Rufgruppe oder Follow-Me zum Telefon kam, oder
  Asterisk spielt eine 8-kHz-Ansage), was Asterisk beim Transkodieren liest und schreibt,
  ob Medien (**SRTP**) und Signalisierung (**TLS**) verschlüsselt waren (✓ / ✗, —, wenn es
  sich nicht belegen lässt; TLS zählt als ✓, wenn die SIP-Adresse des Anrufs es verlangt
  oder der Endpunkt einen TLS-Transport wie `0.0.0.0-tls` nutzt), und dem **Medienpfad**
  (*direkt*, *über Asterisk*, *Konferenz (Mix)*). Darunter je Kanal die **Sprachqualität
  (RTCP)**: was **Asterisk empfängt** von dieser Seite (von Asterisk gemessen) und was die
  **Gegenstelle empfängt** von Asterisk (vom Endpunkt gemeldet) — die durchschnittliche
  **Datenrate**, verlorene Pakete mit der **Spitze** (schlechtestes Berichtsintervall von
  ca. 5 Sekunden), Jitter (Durchschnitt / Maximum) und die Umlaufzeit (**RTT**). Die
  Datenrate stammt aus den Zählern des Senders und braucht etwa 10 s Gesprächszeit; je nach
  Gerät enthält sie den RTP-Header oder die SRTP-Prüfsumme, kann also bis zu etwa 5 kbit/s
  über der reinen Codec-Rate liegen (z. B. ≈ 68 statt 64 kbit/s bei G.722). Ein **—**
  bedeutet, dass für diese Seite kein Bericht kam; Werte werden nicht erfunden.
  Mit dem Recht *Technische Details* siehst du zusätzlich die **SIP-Call-ID** mit einem
  Knopf **Kopieren** — zum Einfügen in deinen SIP-Tracer (z. B. Homer) — sowie die
  Signalisierungs- und RTP-Adressen.
  Anrufe aus einem Zeitraum, in dem der Listener getrennt war, zeigen *Codec-Daten nicht
  erfasst*; Anrufe von vor dem Einschalten der Erfassung zeigen nichts.
- **System / Kontext:** die gespielte Ansage und (mit *Technische Details*) der
  Dialplan-Kontext.
- **Gesprächsverlauf:** die Abschnitte des Anrufs der Reihe nach — Verbindungen (↔ zwischen
  zwei Teilnehmern), Ansagen (📢, die gespielte Ansage), IVR-Menüschritte (🎛, welches Menü,
  die Ansage und die Taste, die der Anrufer gedrückt hat), Parken (⏸), Konferenzen und
  Mailbox (✉) — jeweils mit Klingel- und Gesprächszeit. Übergaben und Follow-Me-Sprünge
  erscheinen hier ebenfalls. Hält ein Mitarbeiter den Anrufer, um vor dem Übergeben einen
  Kollegen zu fragen, erscheint diese Rückfrage als eigener Schritt **⟳ Rückfrage** (die
  beiden Mitarbeiter sprechen, während der Anrufer gehalten wird) zwischen den Beinen des
  Anrufers — so gehen die Zeiten auf. Eine Übergabe an ein **Dialplan-Ziel** (z. B. eine
  Custom Destination, die nur eine Ansage spielt, statt einer anderen Nebenstelle) zeigt
  einen Schritt **↪ Weitergeleitet an** mit dem Ziel, an das der Anruf ging. Jeder Schritt,
  der **über ein Amt hinausgeht** (ein normaler abgehender Anruf oder ein nach extern
  weitergeleitetes Bein), trägt den Zusatz **„über &lt;Amt&gt;"**, sodass du siehst, welches
  Amt ihn transportiert hat — auf dieses Amt laufen auch seine Kosten.
  Ein Anruf in einen **Konferenzraum** (FreePBX *Conferences*) zeigt einen Schritt
  **👥 Konferenzraum &lt;Nummer&gt;**: wann der Anrufer im Raum war, wer gleichzeitig noch
  darin war, und die Gesprächszeit — die Zeit zusammen mit mindestens einem weiteren
  Teilnehmer (Warten auf den Leiter oder das Aufsprechen des eigenen Namens zählt nicht).
  Jeder Teilnehmer behält seinen eigenen Anruf im Journal; der Anruf gilt als angenommen,
  sobald jemand im Raum gesprochen hat, und die Raumnummer steht unter *Beteiligt*, sodass
  ein Filter darauf alle Anrufe in diesen Raum findet.

Ein erneuter Klick auf die Zeile klappt sie zu. Offene Zeilen bleiben offen, während sich
das Journal automatisch aktualisiert.

---

## Spalten auswählen

Im Menü **Spalten** blendest du Spalten ein und aus. Deine Auswahl und ihre Reihenfolge
werden **pro Benutzer gespeichert**. Ausgeblendete Spalten behalten ihre Position, beim
erneuten Einblenden landet eine Spalte also wieder an ihrem Platz.

Die Checkbox **Alle Spalten** zeigt vorübergehend jede Spalte (in deiner eingestellten
Reihenfolge), ohne deine gespeicherte Auswahl zu ändern — praktisch für einen schnellen
Gesamtblick oder vor einem breiten Export.

---

## Export & Drucken

Der **Drucker**-Knopf in der Kopfzeile exportiert die **aktuell gefilterten** Anrufe — in
einem Dialog wählst du das Format. Eine Zeilenauswahl gibt es nicht: Der Export enthält
immer genau das, was dein Filter zeigt (alle Treffer, in der aktuellen Sortierung).

- **CSV** — **jede** Spalte, unabhängig davon, was gerade angezeigt wird. UTF-8 mit BOM und
  Semikolon-getrennt, sodass Excel (auch mit deutschen Ländereinstellungen) sie sauber
  öffnet. Dauern stehen in Sekunden, Zeitstempel im ISO-Format, Kosten als reine Zahlen —
  bereit für Pivot-Tabellen.
- **PDF** — ein echtes, herunterladbares PDF in A4 hoch. Es druckt die Spalten, die du
  gerade siehst (die Checkbox **Alle Spalten** wird berücksichtigt). Die Kopfzeile jeder
  Karte trägt zusätzlich einen Eintrag **Merkmale** mit den Status-Abzeichen des Anrufs
  (Queue, FollowMe, weitergeleitet, geparkt, herangeholt) — so stehen sie auch ohne Details
  im Ausdruck. Hak **Gesprächsdetails mitdrucken** an, um jeden Anruf mit seinem vollen
  Verlauf aufzuklappen (Übergaben, Parken, Konferenz, Mailbox, IVR- und Ansage-Schritte,
  Rückfragen, Weiterleitungen und die Kostenaufschlüsselung). Jeder Anruf ist eine in sich
  geschlossene Karte, die nie über einen Seitenumbruch läuft; jede Seite trägt dein Logo,
  den App-Titel, die **aktiven Filter im Klartext** und eine Fußzeile **Seite x/y**.
  - Sind Kosten konfiguriert, beginnt das PDF direkt unter der Filterzeile mit einer
    **Kostenübersicht**: **Kosten** und **Kosten real** pro Amt (nur Ämter, die in der
    aktuellen Ansicht Kosten haben), dazu eine Zeile **Summe**, wenn mehr als ein Amt
    abgerechnet wird.

Ein Klick auf ein Format zeigt kurz einen **Kreisel**, während die Datei erzeugt wird, und
startet den Download, sobald sie fertig ist — ein großes PDF (Tausende Anrufe) kann ein
paar Sekunden dauern.

> Die Grenze der **freien Version** gilt auch hier: Ein Export enthält höchstens die ersten
> 100 Anrufe. Siehe [LICENSE.md](LICENSE.md).

---

## Blättern

Ganz unten: die Gesamtzahl der passenden Anrufe, eine Auswahl **pro Seite**
(100 / 250 / 500) und die Seitennavigation.

> In der **freien Version** zeigt das Journal höchstens die 100 neuesten Anrufe, und die
> Engine behält nur die letzten 30 Tage; Operator-Panel, Voicemail, Aufnahmen,
> Telefonbücher und die Codec- & Medien-Erfassung (Spalte Codecs, Suche mit `codec:`) sind
> nicht verfügbar. Siehe [LICENSE.md](LICENSE.md).

---

## Kostenanalyse

Die Ansicht **Kosten** schlüsselt deine Anrufkosten für den aktuellen Filter nach **Amt →
Zone → Nebenstelle** auf. Sie folgt den abgerechneten **abgehenden Beinen** und erfasst
damit auch eingehende Anrufe, die nach extern **weitergeleitet** wurden (FollowMe/Übergabe)
— jedes Bein zählt auf dem Amt, über das es tatsächlich hinausging, und bei der
Nebenstelle, die dafür verantwortlich war (die gewählt hat oder deren Weiterleitung es
hinausgeschickt hat). Dafür braucht es eine Tarifdatei — siehe [COSTS.md](COSTS.md).

### Kennzahlen
Eine Reihe Summen für den aktuellen Filter: **Kosten** (brutto), **Kosten real** (nach
Freiminuten), **Ersparnis (Freiminuten)** (was dir die Freiminuten gespart haben),
**Gesprächsdauer abgehend** (die abgerechnete Zeit) und **Abgehende Gespräche** (die Anzahl
der abgerechneten Beine).

### Diagramme
Drei Diagramme: **Kosten je Monat** nimmt allein eine Zeile in voller Breite ein, darunter
stehen **Kosten real je Zone** und **Kosten pro Nebenstelle** nebeneinander.
- **Kosten je Monat** — Brutto- und Real-Kosten pro Monat (deine „Telefonrechnung" im
  Zeitverlauf), mit €-Achse. Bei langen Zeiträumen werden die Monatsbeschriftungen
  ausgedünnt, damit sie lesbar bleiben (die Balken bleiben monatlich — der Monat ist die
  Abrechnungseinheit). Mit dem Knopf **Vergrößern** (oben rechts) öffnest du es groß in
  einem Overlay.
- **Kosten real je Zone** — wohin das Geld geht (National, Mobil, International …).
- **Kosten pro Nebenstelle** — Brutto- und Real-Kosten pro Nebenstelle, neben jedem Balken
  als `brutto / real` angezeigt.

### Aufschlüsselung (Amt → Zone → Nebenstelle)
Eine Liste, die du in drei Ebenen aufklappst:
- **Amt** — Gesamtdauer, Kosten und Kosten real.
- **Zone** (ein Amt aufklappen) — dasselbe pro Zone, dazu das verbleibende
  Freiminuten-**Kontingent**. Umfasst dein Zeitraum mehrere Monate, gibt es keinen einzelnen
  Kontingent-Wert; angezeigt wird dann der **niedrigste** verbleibende Wert im Zeitraum (mit
  vorangestelltem `min.`).
- **Nebenstelle** (eine Zone aufklappen) — pro Nebenstelle in dieser Zone. Die **Kosten real
  pro Nebenstelle werden fair aufgeteilt**, im Verhältnis der *abgerechneten* Sekunden jeder
  Nebenstelle — so wird der Freiminuten-Rabatt nicht einfach dem gutgeschrieben, der
  zufällig zuletzt telefoniert hat.

Jede Zonen- und Nebenstellen-Zeile hat einen Link **Details**, der in die Ansicht **Liste**
springt, gefiltert auf dieses Amt / diese Zone. Der aktive Zonenfilter erscheint dort als
entfernbares Kärtchen **„Zone: …"** über der Liste.

### Export
Der **Drucker**-Knopf exportiert die Aufschlüsselung für den aktuellen Filter:
- **PDF** — mit dem Titel *Kostenanalyse*: Kopf mit deinen Filtern, die Kennzahlen, die drei
  Diagramme, dann die vollständig aufgeklappte Liste. Eine Zone wird nie über einen
  Seitenumbruch geteilt (außer sie hat mehr Nebenstellen, als auf eine Seite passen), und
  der Tabellenkopf wiederholt sich auf jeder Seite.
- **CSV** — eine flache Tabelle, die die aufgeklappte Liste abbildet: eine Zeile pro Ebene
  (mit einer Spalte *Ebene*) und oben eine Summenzeile, bereit für Pivot-Tabellen in Excel.
  Diagramme sind rein visuell, die CSV enthält also die Daten dahinter.

---

## Statistik

Die Ansicht **Statistik** fasst die Anrufe deines aktuellen Filters zu Kennzahlen,
Diagrammen und Tabellen zusammen. Anders als Kosten umfasst sie **alle Richtungen**, und die
Checkboxen der Filterzeile (*Nur Erfolgreiche*, *Nur Verpasste*, *Nur Externe*, *Ignorierte
zeigen*) gelten auch hier — jede Zahl spiegelt also genau die Anrufe, die du ausgewählt
hast.

### Kennzahlen
Anrufe gesamt · Angenommen (mit Annahmequote) · Verpasst · Ø Klingelzeit ·
Ø Gesprächsdauer.

### Anrufvolumen im Zeitverlauf
Ein gestapeltes Balkendiagramm (kommend / gehend / intern) mit **automatischer
Zeiteinheit**: Tag, Woche, Monat, Quartal oder Jahr, so gewählt, dass das Diagramm lesbar
bleibt (etwa ≤ 40 Balken). Um in Wochen- oder Tagesdetails hineinzuzoomen, **verkleinere den
Zeitraum** — das Diagramm teilt automatisch neu ein; der Datumsfilter ist dein Zoom. Bei
vielen Balken werden die Beschriftungen ausgedünnt. Mit dem Knopf **Vergrößern** (oben
rechts) öffnest du ein großes Overlay.

### Richtung & Status
Zwei Ringdiagramme — Anrufe **Nach Richtung** und **Nach Status** (angenommen / verpasst /
Mailbox / sonstige) — jeweils mit Anzahl und Prozent.

### Klingelzeit
Wie lange Anrufer warteten, bis ein Anruf angenommen wurde, gruppiert in `< 5 s`, `5–10 s`,
`10–20 s`, `20–30 s`, `≥ 30 s`.

### Heatmap Wochentag × Stunde
Ein Raster aus 7 × 24 Feldern; je dunkler ein Feld, desto mehr Anrufe an diesem Wochentag
zu dieser Stunde — deine Stoßzeiten auf einen Blick.

### Warteschlangen
Eine Zeile pro Warteschlange: **Angeboten**, **Angenommen**, **Abgebrochen** (Anrufer hat
beim Warten aufgelegt), **Annahmequote**, **Service-Level** (Anteil innerhalb von 20 s
angenommen) und **Ø Wartezeit**. Das ist die verlässliche Sicht auf „Wie gut gehen wir
ran?". Ein Anruf, der durch mehrere Warteschlangen lief, zählt bei jeder davon.

### Pro Nebenstelle
Pro Nebenstelle: Anzahl kommend / gehend / intern, angenommen, Ø Gespräch, Ø Klingelzeit und
gesamte Gesprächszeit. Beachte: Gezählt wird die Nebenstelle, die einen Anruf
**angenommen** hat — bei parallel klingelnden Queues zeigt das, wer abgenommen hat, keine
„Annahmequote" pro Agent (die lässt sich aus gefalteten Anrufdaten nicht verlässlich
ermitteln; dafür ist die Tabelle Warteschlangen da).

### Top-Anrufer / Top-Ziele, pro Amt
Die häufigsten externen **Anrufer** und **Ziele** sowie eine Übersicht **Pro Amt**.

### Export
Der **Drucker**-Knopf exportiert die Statistik für den aktuellen Filter:
- **PDF** — mit dem Titel *Statistik*: Kopf mit deinen Filtern, die Kennzahlen, das
  Anrufvolumen-Diagramm, die Heatmap, waagerechte Balken für Richtung/Status/Klingelzeit,
  dann die Tabellen (Warteschlangen, pro Nebenstelle, Top-Anrufer/-Ziele, pro Amt). Eine
  Tabelle wird nie über einen Seitenumbruch geteilt, außer sie ist länger als eine ganze
  Seite, und der Tabellenkopf wiederholt sich auf jeder Seite.
- **CSV** — eine Datei mit einem Abschnitt pro Block (Kennzahlen, Volumen, Warteschlangen,
  pro Nebenstelle, Top-Anrufer/-Ziele, pro Amt); Dauern stehen in Sekunden, damit sie sich
  leicht weiterverarbeiten lassen. Diagramme sind rein visuell, die CSV enthält also die
  Daten dahinter.

---

## Operator-Panel

*Lizenzierte Version, Recht **Panel öffnen**, eingerichtet wie in
[CONFIGURATION.md → panel](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).*
Der Reiter **Panel** (ganz links in der Kopfzeile) zeigt die Telefonanlage live — er
aktualisiert sich innerhalb einer Sekunde von selbst. Hast du das Panel-Recht, ist das Panel
auch deine **Startseite** (nach der Anmeldung und beim Aufruf der reinen Adresse); das
Journal liegt unter dem Reiter *Liste* (`/journal`). Links mit Filtern öffnen weiterhin
direkt das Journal.

Rechtenamen in *kursiv* beziehen sich auf die [Rechtetabelle](#rechte).

### Was du siehst

- **Nebenstellen** als Kacheln, eingefärbt wie die Besetztlampen am Telefon: **grün** frei,
  **gelb** klingelt (pulsierend), **rot** belegt, **violett** gehalten, **grau** nicht
  erreichbar; gestrichelt = eine virtuelle Nebenstelle ohne Telefon (z. B. eine
  Voicemail-Box, mit der Zahl ihrer neuen Nachrichten). Solange ein Anrufer **in der
  Voicemail** einer solchen Box ist (Ansage oder Aufsprechen — Asterisk unterscheidet das
  nicht) oder jemand **die Mailbox abhört**, zeigt die Kachel der Box das als Zeile mit dem
  Anrufer und der Dauer (bis zu zwei Sekunden verzögert: Asterisk meldet das nur auf
  Nachfrage). Ein **eingehendes Fax** erscheint genauso auf der Kachel der Nebenstelle des
  Fax-Empfängers.
- Jede Kachel hat Platz für **zwei Zeilen** (Gespräche), damit das Raster nicht springt,
  wenn Gespräche kommen und gehen; ein drittes Gespräch erscheint als **+1** im Kachelkopf.
  Jede Zeile zeigt einen farbigen Punkt für das Geschehen (rot spricht, gelb klingelt,
  violettes Quadrat hält / wird gehalten), ↘ ankommend / ↗ abgehend, den Gesprächspartner
  und die Dauer. Nummer und Name des Partners **wechseln alle 3 Sekunden**. **Fahr mit der
  Maus über eine Zeile** (oder fokussiere sie per Tastatur) für die Details: volle Nummer
  und Name, das **Amt**, die **Queue**, falls der Anruf über eine kam, und — sobald die
  Codec-Erfassung ihn gemessen hat — den **Codec** der Leitung und der Gegenstelle, mit
  Hinweis, wenn Asterisk transkodiert. Abzeichen im Kachelkopf markieren **DND** (Nicht
  stören), **FM** (Follow-Me), einen **Dreier** am Telefon, ein **Auge** (jemand hört mit —
  nur sichtbar für Benutzer, die selbst mithören dürfen), den Umschlag **✉** (Voicemail) und
  einen roten **●** (es gibt Aufnahmen).
- **Dein Arbeitsplatz** — die Nebenstelle, an der du sitzt — steht als doppelt breite
  Kachel vorn (Pin-Symbol). Hast du mehr als eine eigene Nebenstelle (zugewiesen unter
  [Benutzer & Rollen](#benutzer--rollen)), wählst du sie unter **Ich sitze an** links in der
  Werkzeugleiste; die Wahl wird **pro Browser** gemerkt (Büro-PC an der einen Nebenstelle,
  Heim-PC an einer anderen). Hat diese Nebenstelle mehrere Geräte, wählst du das Gerät
  daneben. Deine übrigen Nebenstellen folgen, markiert mit einem Personen-Symbol; der Rest
  ist nach **Nummer** oder **Name** sortiert (Sortier-Knopf, wird gemerkt). Das Suchfeld
  filtert nach Nebenstelle, Name oder der Nummer eines laufenden Gesprächs.

- **Kurzwahlen** — wichtige Nummern, die dein Admin angelegt hat (externe oder interne
  Funktionen wie eine Ansage) — folgen den Nebenstellen als Kacheln mit einem **Stern**,
  genauso sortiert. Blau = frei; solange ein Gespräch mit der Nummer läuft, wird die Kachel
  gelb (klingelt) oder rot (Gespräch) und zeigt, welche Nebenstelle es führt — eine externe
  Nummer wird in jeder Schreibweise erkannt (`0221 …` = `+49 221 …`). Ob eine Nummer intern
  ist, wird im Dialplan der Anlage nachgeschlagen (Nebenstellen, Hints und eigener Dialplan
  wie ein `*`-Code) — eine kurze externe Nummer wie `112` gilt also als extern; interne
  Nummern ohne Hint zeigen keinen Zustand. Externe und lange Nummern stehen nicht auf der
  Kachel, nur der Name; die Nummer zeigt der Tooltip. Ein Klick wirkt wie auf einer Nebenstellen-Kachel:
  *Anrufen*, im Gespräch *Rückfrage* / *Übergeben*; ein Gespräch darauf ziehen übergibt es.
  Eine Kurzwahl mit **Direkt wählen** (z. B. ein Türöffner) wählt beim Klick sofort, ohne
  Nachfrage — im Gespräch bleibt das Menü mit Rückfrage/Übergeben.
  Mit dem Recht *Eigene Kurzwahlen anlegen* legst du unter [Dein Konto](#eigene-kurzwahlen)
  **eigene** Kurzwahlen an — sie stehen zwischen den anderen, mit einer **Person** statt des
  Sterns, und nur du siehst sie. Schneller: **Als Kurzwahl speichern** im Menü einer
  Gesprächszeile (Nebenstelle, Amt oder Queue), eines Kontakts in der Kontakt-Leiste oder
  eines Wählvorschlags — der Name ist aus Telefonbuch bzw. Anruferkennung vorbelegt, *Direkt
  wählen* nach Wunsch. An deiner eigenen Kurzwahl-Kachel löscht **Kurzwahl entfernen** sie.

Unter den Nebenstellen drei Spalten (auf schmalen Bildschirmen weniger), jede scrollt für
sich:

- **Queues:** eine Zeile pro Queue mit einem Kärtchen, das ihre Anrufe zählt (gelb, solange
  jemand wartet). Darunter eine Zeile pro Anruf: zuerst **wartend** oder **klingelnd** (mit
  den Nebenstellen, bei denen es klingelt), mit Position und Wartezeit, dann Anrufe, die ein
  Agent **angenommen** hat (⇄ Agent), solange sie dauern, neueste zuerst. Mit der Maus über
  einen Anruf fahren zeigt die Details. Der Pfeil vor der Queue klappt die **Agents** aus
  (wird pro Browser gemerkt), mit ihrem Zustand (durchgestrichen = pausiert; **gestrichelt
  mit Anmelde-Symbol** = dynamisch angemeldet, z. B. mit `*45`). Änderungen in FreePBX
  erscheinen ein paar Sekunden nach **Apply Config**; außerdem prüft das Panel alle 5 Minuten
  alle Queues neu.
- **Ämter:** laufende Gespräche pro Amt mit der externen Nummer und der internen
  Nebenstelle; mit der Maus darüber: Richtung, Nummer und Name, die Codecs und ob Asterisk
  transkodiert.
- **Parken** und **Konferenzräume:** jeder Parkplatz-Bereich mit seiner **Parknummer**
  (wohin du einen Anruf übergibst, um ihn zu parken, z. B. `600`) und den **belegten**
  Plätzen, mit Angabe, wer dort wie lange geparkt ist. **Alle** Konferenzräume der FreePBX mit ihrer
  Nummer, auch wenn sie leer sind; belegte Räume listen ihre Teilnehmer (Leiter, stumm) —
  wer **gerade spricht**, ist grün hervorgehoben.

Der Punkt in der Kopfzeile zeigt die Verbindung: **live** oder *Verbindung zur Anlage
unterbrochen*, wenn der Container `cdrj-ami` Asterisk nicht erreicht. Die Seite **erholt
sich von selbst** — auch während die Container bei einem Update neu starten; neu laden musst
du sie nicht. Admins mit dem Recht *Einstellungen* sehen oben einen **gelben Balken**, wenn
dem AMI-User Rechte für einige Panel-Funktionen fehlen (mit den fehlenden Rechten und den
betroffenen Funktionen).

### Die Werkzeugleiste

Die Werkzeugleiste wirkt auf **deinen Arbeitsplatz** (die unter *Ich sitze an* gewählte
Nebenstelle) und dessen **aktives Gespräch**. Knöpfe, die gerade nichts bewirken, sind
ausgegraut; Knöpfe, für die dir das Recht fehlt, werden nicht angezeigt. Auf schmalen
Bildschirmen (Handy) bricht die Werkzeugleiste zwischen ihren drei Gruppen um.

| Knopf | Was er macht | Recht |
|---|---|---|
| **Wahlfeld** + grüner Knopf **Anrufen** | Eine Nummer von deinem Arbeitsplatz aus wählen (siehe [Wählen](#wählen-und-annehmen)). Während an deinem Arbeitsplatz ein Anruf **klingelt** und eine Telefonsteuerung eingerichtet ist, pulsiert der Knopf schnell: Ein Klick (bei leerem Feld) **nimmt an**. | *Wählen* (Annehmen: *Telefon fernsteuern (annehmen, halten)*) |
| **Kontakte** (Buch) | Öffnet die Kontakt-Seitenleiste (siehe [Kontakte](#kontakte--telefonbücher)). | *Globale Telefonbücher sehen* oder *Eigene Telefonbücher anlegen/sehen* |
| **Auflegen** (rot) | Beendet das aktive Gespräch. Bei einem Anruf, der noch **klingelt**, **weist** er ihn **ab** wie die Ablehnen-Taste am Telefon — der Anrufer bekommt *besetzt* (bzw. die Besetzt-Voicemail). Während einer Rückfrage **bricht** er **die Rückfrage ab** (du bist wieder beim gehaltenen Anrufer). | *Eigene Gespräche steuern* |
| **Halten** (violett) | Hält das aktive Gespräch an deinem Telefon; solange es gehalten wird, pulsiert der Knopf, ein weiterer Klick holt es zurück. Nur mit eingerichteter Telefonsteuerung und einem Telefon, das halten kann. | *Telefon fernsteuern (annehmen, halten)* |
| **Übergeben** (blau →) | Blinde Übergabe: Ziel eintippen oder eine Kachel bzw. einen Konferenzraum anklicken. | *Eigene Gespräche steuern* |
| **Rückfrage** (blau ⇄) | Ruft das Ziel an, während der Anrufer gehalten wird; derselbe Knopf wird dann grün und **schließt die Übergabe ab**. | *Eigene Gespräche steuern* |
| **Parken** (gelbes P) | Parkt das aktive Gespräch auf dem ersten freien Platz. | *Eigene Gespräche steuern* |
| **Aufnahme starten** (rotes Band) | Startet oder beendet die Aufnahme des aktiven Gesprächs; pulsiert während der Aufnahme. | *Eigene Gespräche aufnehmen* |
| **In Konferenz überführen** (violett, drei Personen) | Siehe [Konferenzräume](#konferenzräume). | *Eigene Gespräche steuern* |
| **Kaffeetasse** (gelb) | Nur, wenn dein Arbeitsplatz Agent in einer Queue ist: **Pause in allen meinen Queues** (mit Grund) oder die Pause beenden; pulsiert, solange du pausiert bist — dann bekommst du keine Queue-Anrufe. | *Panel öffnen* |
| **Nicht stören** (rot, Minus) | Schaltet „Nicht stören" deines Arbeitsplatzes ein oder aus; pulsiert, solange es an ist. | *Nicht stören eigene Nebenstellen schalten* |

Bei **zwei aktiven Gesprächen** (z. B. einem Dreier am Telefon) klickst du zuerst das
gemeinte Gespräch auf deiner Arbeitsplatz-Kachel an — es bekommt einen Rahmen, und die
Knöpfe wirken nur auf diesen Teilnehmer.

Neben der Werkzeugleiste: das Suchfeld, die Sortierung (Nummer / Name), **Normal / Kompakt**
(kleinere Kacheln, damit eine Zentrale mehr Nebenstellen auf einmal sieht; wird pro Benutzer
gemerkt), die **Glocke** ([Benachrichtigungen](#benachrichtigungen)) und **?** (Legende: die
Farben von Kacheln und Punkten — rund = eine Person, eckig = gehalten oder eine Maschine wie
Voicemail oder Fax — und die Tastenkürzel).

### Wählen und Annehmen

- **Wählen:** Tipp eine Nummer ins Feld und drück Enter oder den grünen Knopf
  **Anrufen**, oder klick eine Nebenstellen-Kachel an und wähle *Anrufen*. Zuerst klingelt
  dein Telefon; wenn du abhebst, wird die Nummer gewählt (die abgehenden Routen und
  Einschränkungen der FreePBX gelten wie gewohnt). Tippst du die Nummer eines
  **Konferenzraums**, trittst du diesem Raum bei (siehe [Konferenzräume](#konferenzräume)).
- **Auto-Answer:** Dein Telefon hebt von selbst ab, wenn deine Nebenstelle dafür unter
  [Admin → Nebenstellen](#nebenstellen) eingerichtet ist. Das geht immer nur an ein
  einzelnes Gerät; ist neben *Ich sitze an* *alle Geräte* gewählt, klingeln alle, und du
  hebst selbst ab.
- **Vorschläge:** Beim Tippen schlägt das Feld Nebenstellen (mit ihrem Zustand),
  Telefonbuch-Kontakte (nach Name oder Firma, auch beim Tippen von Buchstaben) und
  Nummern/Namen aus dem Journal vor (häufigste zuerst, nur aus Anrufen, die du sehen darfst).
  Ein Buch-Symbol markiert Telefonbuch-Kontakte, ein kleiner Kreis Nummern aus früheren
  Anrufen. **↑/↓ und Enter wählen sofort; ein Klick fragt erst *Diese Nummer anrufen*** —
  der zusätzliche Klick schützt davor, jemanden versehentlich anzurufen. Bis zu 12
  Telefonbuch-Nummern werden vorgeschlagen; gibt es mehr, öffnet die letzte Zeile *Alle
  Treffer im Telefonbuch* die Kontakt-Seitenleiste mit deiner Suche.
- **Annehmen und Halten aus dem Panel** (Recht *Telefon fernsteuern (annehmen, halten)*,
  und ein Admin hat für deine Nebenstelle eine [Telefonsteuerung](#nebenstellen)
  eingerichtet): Klingelt ein Anruf an deinem Arbeitsplatz, pulsiert der grüne Knopf
  **Anrufen** schnell — klick ihn bei leerem Wahlfeld, und dein Telefon nimmt an. Der
  violette Knopf **Halten** hält und holt zurück. Telefone, die nicht halten können (z. B.
  Auerswald COMfortel 2600 IP), bekommen keinen Halten-Knopf. Hat deine Nebenstelle mehrere
  Geräte, wähle zuerst das Gerät neben *Ich sitze an*.
- **Nummern im Journal:** Mit Panel und dem Recht *Wählen* sind Nummern im Journal
  unterstrichen — ein Klick bietet *Diese Nummer anrufen*. Mit dem Recht *Eigene Kurzwahlen
  anlegen* bietet die externe Nummer eines Anrufs außerdem *Als Kurzwahl speichern* (Name und
  *Direkt wählen* wie im Panel).

### Kacheln und Gespräche anklicken

Ein Klick öffnet ein kleines Menü mit dem, was du dort tun kannst:

- **Eine Kachel** (kein Gespräch an deinem Arbeitsplatz): die Nebenstelle *Anrufen*;
  *Heranholen (Pickup)*, solange dort ein Anruf **klingelt** (Recht *Heranholen (Pickup)* —
  dein Arbeitsplatz übernimmt den Anruf, mit Auto-Answer sofort); *Voicemail öffnen*; ihr
  „Nicht stören" / Follow-Me schalten (falls erlaubt). Eine Kachel mit genau **einem**
  Gespräch bietet auch die Aktionen dieses Gesprächs; bei zwei Gesprächen klickst du die
  gemeinte Zeile an.
- **Eine Kachel, während du telefonierst,** bietet statt *Anrufen* **Rückfrage** und
  **Übergeben** an diese Nebenstelle (ein neuer Anruf käme an deinem Telefon nur als zweiter
  eingehender Anruf an). Reine Voicemail-Nebenstellen bieten nur *Übergeben*; ein
  Konferenzraum bietet an, den Anrufer **in den Raum** zu holen.
- **Deine anderen eigenen Nebenstellen:** Ein Klick auf eine Gesprächszeile bietet
  Auflegen, Übergeben, Rückfrage, Parken — dazu **Zu mir holen** (das Gespräch wandert an
  deinen Arbeitsplatz) und Mithören (vielleicht benutzt gerade jemand anderes dieses
  Telefon). Recht *Eigene Gespräche steuern*.
- **Gespräche anderer** (Recht *Fremde Gespräche steuern*, nur Nebenstellen, die deine
  Rolle sieht): **Zu mir holen**, **Übergeben**, **Parken** und **Auflegen**.
- **Anrufer unter Ämter, in einer Queue oder in einer Voicemail-Box:** **Zu mir holen** —
  zuerst klingelt dein Telefon, und erst wenn du abhebst, wird der Anrufer zu dir geholt;
  hebst du nicht ab, bleibt der Anrufer, wo er war. **Ruf umleiten** schickt einen Anrufer
  von einem Amt oder aus einer Queue sofort woandershin — während es noch klingelt, er in
  der Queue wartet oder eine Ansage hört: Ziel eintippen oder eine Kachel anklicken. Klick
  zum Beispiel auf die Kachel einer Voicemail-Box, um den Anrufer direkt auf die Voicemail
  zu schicken (oder tipp den FreePBX-Code für *Direct Voicemail* ein, `*` plus die
  Nebenstelle, z. B. `*901`). Recht *Fremde Gespräche steuern*.
- **Geparkte Gespräche:** Klick unter *Parken* auf einen Platz und wähle *An meinen Platz
  holen*.
- **Mithören, Flüstern, Aufschalten** (je ein eigenes Recht — ab Werk in keiner Rolle;
  Superadmins haben sie): bei einem verbundenen Gespräch einer anderen Nebenstelle oder
  einer deiner eigenen Nebenstellen außer deinem Arbeitsplatz. Nach einer Bestätigung
  klingelt dein Telefon; wenn du abhebst, hörst du mit (die Tasten 4/5/6 wechseln zwischen
  Mithören, Flüstern und Aufschalten). Das **Auge** auf der Kachel zeigt, dass jemand
  mithört. Nebenstellen, die unter [Admin → Nebenstellen](#nebenstellen) als *nicht
  mithörbar* markiert sind, bieten das nie an. Jeder Beginn und jedes Ende wird ins
  [Protokoll](#protokoll) geschrieben.
  > **Rechtlicher Hinweis:** Heimliches Mithören von Gesprächen ist in vielen Ländern
  > strafbar (in Deutschland § 201 StGB); im Unternehmen gelten zusätzlich der Datenschutz
  > und gegebenenfalls die Mitbestimmung des Betriebsrats. Die Gesprächspartner hören
  > **keinen** Ton. AstCDR lässt diese Rechte ab Werk aus und protokolliert jede Nutzung —
  > ob und wie du sie nutzen darfst, musst du selbst klären.

Die Rückmeldung erscheint unten (z. B. *Telefon 21 klingelt …* oder warum Asterisk
abgelehnt hat). Jede Aktion wird ins [Protokoll](#protokoll) geschrieben.

### Ziehen & Ablegen

Zieh ein verbundenes Gespräch auf eine Kachel, um es dorthin zu **übergeben** (beim Ablegen
**Umschalt** gedrückt halten für eine Übergabe mit Rückfrage — nur bei eigenen
Nebenstellen), auf *Parken*, um es zu **parken**, auf einen **Konferenzraum**, um es in den
Raum zu holen, oder auf deinen eigenen Arbeitsplatz, um es **zu dir zu holen**. Ein Anrufer
aus *Ämter*, einer Queue oder einer Voicemail-Box, den du auf deinem Arbeitsplatz ablegst,
wird zu dir geholt; auf jeder anderen Kachel wird er dorthin **umgeleitet**. Die
Beschriftung am Mauszeiger sagt, was passieren wird; Esc bricht ab. Auf Touch-Bildschirmen
ein Gespräch einen Moment gedrückt halten, dann ziehen. Es gelten dieselben Rechte wie für die Menüs.

### Queues

Klapp die Agents einer Queue aus und klick einen an, um ihn zu **pausieren** (mit einem
Grund aus der Liste, die dein Admin unter [Admin → Nebenstellen](#nebenstellen) pflegt,
oder ohne), die **Pause aufzuheben** oder einen dynamischen Agent **abzumelden**. Ein Agent
in mehreren Queues lässt sich **in allen Queues** auf einmal pausieren (oder die Pause
aufheben) — in allen Queues, die deine Rolle sieht; andere bleiben unberührt. Pausieren
geht für feste und dynamische Agents gleichermaßen (die Pause eines festen Mitglieds hält
bis zum nächsten *Apply Config*, wie in Asterisk); An- und Abmelden nur für dynamische.
Abgemeldete dynamische Agents erscheinen als blasse, gestrichelte Kärtchen — ein Klick
**meldet an**; angeboten werden die Queues, in denen FreePBX die Nebenstelle als
dynamischen Agent führt. Für deine eigenen Agent-Einträge reicht das Panel-Recht; für die
aller anderen brauchst du *Queues steuern*. Für dich selbst ist der Kaffeetassen-Knopf in
der Werkzeugleiste der schnellste Weg.

### Konferenzräume

- **Beitreten:** Klick einen Raum an (frei oder belegt) und wähle **Konferenz beitreten** —
  oder tipp die Raumnummer ins Wahlfeld: Dein Telefon klingelt, und wenn du abhebst, bist du
  im Raum (Recht *Wählen*). Du trittst als **Leiter** bei, wenn du das Recht *Konferenzen
  steuern* hast oder einen **leeren** Raum **ohne Teilnehmer-PIN** öffnest; sonst behandelt
  FreePBX das wie gewohnt (PIN-Abfrage, Leiter nur mit der Admin-PIN). Mehrere Leiter in
  einem Raum sind kein Problem.
- **Ein Gespräch in einen Raum holen:** Zieh es auf den Raum, klick den Raum an, während du
  im Gespräch bist (*In Konferenzraum …*), oder nimm den Knopf **Übergeben** und klick dann
  den Raum an (oder tipp seine Nummer). Der Anrufer tritt als normaler Teilnehmer bei — nie
  als Leiter. In Räume mit PIN kommt er nur dann ohne PIN-Abfrage, wenn du *Konferenzen steuern*
  hast; sonst fragt FreePBX ihn nach der PIN.
- **In Konferenz überführen** (Werkzeugleiste, violetter Knopf mit drei Personen; Recht
  *Eigene Gespräche steuern*): Während eines Gesprächs, einer Rückfrage oder während dein
  Telefon selbst einen Dreier hält, holt er alle in einen freien Konferenzraum: Dein Telefon
  bleibt in der Leitung (nichts klingelt), die Gegenseite (bzw. die Gegenseiten) kommt
  ebenfalls in den Raum, und du wirst **Leiter** des Raums. Die Räume stammen aus dem
  Bereich unter *Admin → Nebenstellen → Konferenzräume zum Überführen* (ohne ihn ist der
  Knopf aus); genommen wird der kleinste freie Raum. Nimm dafür eigene FreePBX-Konferenzräume
  ohne PIN und ohne „Warten auf den Leiter", die von außen nicht erreichbar sind. Bei einem
  Dreier am Telefon wird die zweite Leitung des Telefons danach aufgelegt.
- **Den Raum steuern** (Recht *Konferenzen steuern*, oder du sitzt als Leiter im Raum):
  Klick einen Teilnehmer an zum **Stummschalten / Freigeben** oder **Hinauswerfen**; klick
  den Raumkopf für **Alle stummschalten** / **Alle freigeben** (Leiter bleiben hörbar),
  **Raum sperren / Raum entsperren** (gesperrt: niemand Neues kann beitreten, außer Leitern)
  und **Konferenz beenden** (nach einer Bestätigung werden alle getrennt, auch Leiter).

### Nicht stören und Follow-Me

Der rote Knopf mit dem Minuszeichen in der Werkzeugleiste schaltet **„Nicht stören"**
deines Arbeitsplatzes. Für andere Nebenstellen wählst du im Kachelmenü *Nicht stören
einschalten* / *Nicht stören ausschalten*, oder klickst auf das rote Abzeichen **DND**, um
es auszuschalten. Nebenstellen, deren Follow-Me mehr Ziele als sich selbst enthält, zeigen
ein Abzeichen **FM**: grün = an, grau = aus; mit der Maus darüber siehst du die Ziele, ein
Klick schaltet um (wie `*76` / `*21` am Telefon; die BLF-Tasten des Telefons ziehen mit).
Rechte: *Nicht stören eigene Nebenstellen schalten* / *Nicht stören fremde Nebenstellen
schalten* und *Follow-Me eigene Nebenstellen schalten* / *Follow-Me fremde Nebenstellen
schalten*.

### Voicemail

Klick auf den Umschlag **✉** einer Kachel (mit Zahl, wenn es neue Nachrichten gibt; blass,
wenn keine da sind) oder wähle im Kachelmenü *Voicemail öffnen*. Rechts öffnet sich eine
Seitenleiste mit den Nachrichten der Box — **Neu** und **Gehört**, neueste zuerst, jeweils
mit Anrufer, Zeit und Länge. Pro Nachricht: **▶ Anhören** (Player oben in der Seitenleiste
mit breitem Schieberegler zum Spulen, ±5 Sekunden, Geschwindigkeit 1× / 1,5× / 2×), **Als
gehört markieren** (oder wieder **Als neu markieren**), **Weiterleiten an …** eine andere
Box, die du sehen kannst (das Original bleibt), **Herunterladen** und **Löschen** (nach
einer Bestätigung — das lässt sich nicht rückgängig machen). Abspielen markiert eine
Nachricht **nicht** als gehört; das tut nur der Knopf. Gehört / neu / löschen aktualisieren
den Zähler und die Lampe am Telefon sofort. Als GSM gespeicherte Nachrichten kann der
Browser nicht abspielen — lade sie stattdessen herunter.

Rechte: *Eigene Voicemail* für die Boxen deiner eigenen Nebenstellen (einschließlich dir
zugewiesener virtueller), *Gruppen-Voicemail* für virtuelle Nebenstellen ohne Telefon (z. B.
eine gemeinsame Box wie 901), die dir nicht zugewiesen sind, *Fremde Voicemail* für die
Boxen aller anderen Nebenstellen, die deine Rolle sieht. Abspielen, Herunterladen, Löschen
und Weiterleiten werden ins [Protokoll](#protokoll) geschrieben.

### Aufnahmen

- **Aufnahmen anhören:** Ein kleiner roter **●** auf einer Kachel (oder einem Queue-Kopf)
  bedeutet, dass es Gesprächsaufnahmen für diese Nebenstelle oder Queue gibt. Klick ihn an:
  Die Seitenleiste listet sie nach Tagen — Gesprächspartner, Zeit, Länge, beteiligte
  Nebenstellen — mit **▶ Anhören** (derselbe Player wie bei der Voicemail),
  **Herunterladen** und **Löschen**. Im Journal öffnen die Spalte *Aufz.* und die
  Anrufdetails dieselbe Seitenleiste für einen Anruf. Hat ein Anruf mehrere Aufnahmen (z. B.
  nach einer Übergabe), fragt Löschen, ob **Nur diese** oder **alle Aufnahmen des Anrufs**
  entfernt werden sollen. Gelöschte Aufnahmen bleiben in den Anrufdetails als *Aufnahme
  gelöscht* aufgeführt, mit Angabe, wer sie wann gelöscht hat.
- **Rechte** sind neunfach aufgeteilt: *Anhören*, *Herunterladen* und *Löschen* — jeweils
  für **eigene** Aufnahmen (Gespräche mit einer deiner Nebenstellen), **fremde** Aufnahmen
  (andere Nebenstellen, die du sehen kannst) und **Queue**-Aufnahmen (Anrufe über eine
  Queue, die du sehen kannst). Ein ausgegrauter Papierkorb erklärt, warum Löschen nicht
  möglich ist (z. B. ist die Ablage nur lesend eingebunden — siehe TROUBLESHOOTING.md).
- **Fehlende Dateien:** Aufnahmen, die die CDR nennt, die aber nicht mehr in der Ablage
  liegen, erscheinen als *Datei fehlt in der Ablage*; mit dem Lösch-Recht entfernt der
  Papierkorb den Eintrag.
- **Ein Gespräch aufnehmen** (Rechte *Eigene Gespräche aufnehmen* / *Fremde Gespräche
  aufnehmen*): Der Aufnahme-Knopf in der Werkzeugleiste startet oder beendet die Aufnahme
  des aktiven Gesprächs an deinem Arbeitsplatz; für andere Gespräche wählst du im Menü des
  Gesprächs *Aufnahme starten* / *Aufnahme beenden*. Ein pulsierendes **Band**-Symbol vor
  dem Gesprächspartner zeigt, dass ein Gespräch aufgenommen wird — auch bei Aufnahmen, die
  FreePBX selbst gestartet hat, und auch an den Anrufen unter einer Queue. Aufnahmen, die
  mit `*1` am Telefon oder im Panel gestartet wurden, lassen sich beenden; Aufnahmen, die
  eine feste Regel der FreePBX vorschreibt (*Call Recording: Force*, z. B. in einer Queue),
  nicht — dafür bietet das Panel kein *Aufnahme beenden* an. Aufnahmen landen in der
  normalen Ablage der FreePBX und erscheinen im Journal. Start und Stopp werden ins
  Protokoll geschrieben.

### Kontakte & Telefonbücher

*Rechte Globale Telefonbücher sehen und Eigene Telefonbücher anlegen/sehen; eingerichtet
von einem Admin unter [Admin → Telefonbücher](#telefonbücher).*

- Der **Buch-Knopf** direkt neben dem Wählknopf öffnet die Kontakt-Seitenleiste: oben ein
  Suchfeld (Name, Firma oder Nummer), Sortierung *Name, Vorname* oder *Vorname Name*,
  Kontakte nach Buchstaben gruppiert mit ihren Nummern (Büro / Mobil / Privat) und ihrer
  Herkunft. Klick eine Nummer an und bestätige *Diese Nummer anrufen*, um sie von deinem
  Arbeitsplatz aus zu wählen.
- Anrufe zeigen den **Namen aus dem Telefonbuch** statt des übermittelten Anrufernamens —
  im Panel, in Benachrichtigungen und im Journal (Liste, Details, PDF/CSV). Der übermittelte
  Name bleibt in den Anrufdetails und im Panel-Tooltip sichtbar (*Übermittelt*). Ein kleines
  Buch-Symbol markiert Namen aus dem Telefonbuch.
- Die Journal-Suche findet Anrufe auch nach Kontaktname oder Firma, selbst wenn der Anruf
  selbst keinen Namen mitbrachte.
- **Dein eigenes Adressbuch:** Auf deiner [Kontoseite](#dein-konto) kannst du ein
  CardDAV-Adressbuch einbinden (z. B. aus deiner Nextcloud, mit App-Passwort). Seine
  Kontakte siehst nur du; sie gehen den globalen Telefonbüchern vor.

### Benachrichtigungen

Die **Glocke** in der Werkzeugleiste legt fest, welche Ereignisse als Desktop-Benachrichtigung
erscheinen (Windows-Infobereich, macOS-Mitteilungszentrale): *Anruf an meinen
Nebenstellen*, *Anruf an anderen Nebenstellen (heranholbar)* (nur mit dem Recht *Heranholen
(Pickup)*), *Nicht angenommener Anruf an meinen Nebenstellen*, *Neue Voicemail in meinen
Boxen*, *Anrufer wartet in einer meiner Queues* — und ob eine Benachrichtigung *stehen
bleibt, bis ich sie wegklicke*. **Benachrichtigungen erlauben** fragt den Browser einmalig
um Erlaubnis; **Test-Benachrichtigung** zeigt sofort eine. Benachrichtigungen erscheinen,
solange AstCDR geöffnet ist (Browser-Tab oder installierte App) und sein Fenster nicht im
Vordergrund steht; ein Klick darauf holt das Panel nach vorn (bei Voicemail öffnet er die
Box). Auf iPad/iPhone funktionieren sie nur in der installierten App.

### Tastatur, Touch und App

- **Tastenkürzel** (auch in der Legende hinter **?**): `/` Wahlfeld, `F` Suche,
  `↑`/`↓` Vorschlag auswählen, `Enter` wählen, `Esc` Menü oder Seitenleiste schließen,
  `?` Legende.
- **Touch (iPad, Tablets, Handys):** Tipp auf eine Gesprächszeile oder Kachel, um sofort ihr
  Menü zu öffnen — die Details, die eine Maus beim Darüberfahren zeigt (Amt, Codec, Queue
  …), stehen oben im Menü. Auf Touch-Bildschirmen sind die Knöpfe größer. Maus oder
  Trackpad funktionieren wie gewohnt.
- **Als App installieren:** Der Bildschirm-Knopf in der Kopfzeile installiert AstCDR als App
  (Chrome / Edge: eigenes Fenster ohne Adresszeile, eigenes Taskleisten-Symbol). Auf
  iPad/iPhone erklärt er den Weg über Safari: *Teilen → Zum Home-Bildschirm* — AstCDR
  startet dann im Vollbild. Das braucht HTTPS (deinen Reverse-Proxy); der Knopf erscheint
  nur, wo der Browser das anbietet.
- Nach einem **Update** auf eine neue Version laden sich ein offenes Panel und ein offenes
  Journal (solange *Live* an ist) innerhalb von Sekunden einmal selbst neu, damit Skript,
  Styles und Fußzeile zur neuen Version passen. Andere Seiten (Statistik, Kosten,
  Verwaltung) zeigen die neue Version ab dem nächsten Klick. Ist deine Sitzung
  abgelaufen, bringt dich das Panel zur Anmeldeseite.

---

## Dein Konto

Klick auf **deinen Namen** in der Kopfzeile, um deine Kontoseite zu öffnen.

### Passwort (lokale Benutzer)

Meldest du dich mit einem **lokalen Konto** an (Login-Name oder E-Mail und Passwort, vom
Admin angelegt), änderst du hier dein Passwort: aktuelles Passwort, neues Passwort zweimal.
Die Seite zeigt die Passwort-Regeln (Vorgabe: mindestens 10 Zeichen, davon ein
Großbuchstabe und eine Ziffer). Nach der Änderung bleibst du auf diesem Gerät angemeldet;
**alle anderen Geräte werden abgemeldet**.

**Passwort vergessen?** Ist E-Mail eingerichtet und hat dein Admin das Recht *Passwort
vergessen* mindestens einer Rolle gegeben, zeigt die Anmeldeseite **Passwort vergessen?**.
Wirken tut es für dich nur, wenn eine **deiner** Rollen das Recht hat: Login-Name oder E-Mail
eingeben, und du bekommst einen Link zum Neusetzen (eine Stunde gültig). Die Seite verrät nie,
ob es ein Konto gibt. Konten mit SSO-Anmeldung (OIDC) ändern ihr Passwort beim
Identity-Provider.

### E-Mail-Benachrichtigungen

Hat der Betreiber E-Mail eingerichtet (siehe die `email`-Konfiguration des Betreibers),
siehst du die Adresse, an die die Mails gehen (sie stammt aus deinem Konto und ist hier
nicht änderbar), einen Knopf **Test-E-Mail senden** zum Prüfen der Zustellung und
Checkboxen:

- **Kostenwarnungen** — eine E-Mail, wenn die Monatskosten eines Amts eine vom Betreiber
  konfigurierte Schwelle überschreiten.
- **Kontingentwarnungen** — eine E-Mail, wenn das Freiminuten-Kontingent einer Zone für den
  Monat knapp wird (oder aufgebraucht ist).
- **Fehler und Warnungen** *(nur mit dem Recht Einstellungen)* — eine E-Mail, wenn etwas
  Aufmerksamkeit braucht: Die Datenerfassung geht offline, die Datenbank der Telefonanlage
  ist nicht mehr erreichbar, die Tarifdatei hat Fehler oder die Lizenz ist ungültig. Eine
  kurze E-Mail **Behoben** folgt, sobald der Zustand vorbei ist.

Alle E-Mails kommen in **deiner** Sprache. Jede Checkbox ist ab Werk aus — du entscheidest
dich bewusst dafür. Warnungen werden einmal pro Ereignis verschickt (z. B. einmal pro
Schwelle und Monat), nie bei jedem Anruf. Welche Ämter/Zonen Schwellen haben, legt der
Betreiber in der Tarifdatei fest.

### Mein Adressbuch

Mit dem Recht *Eigene Telefonbücher anlegen/sehen* (lizenzierte Version) kannst du **ein**
eigenes CardDAV-Adressbuch einbinden — URL, Benutzer und Passwort / App-Passwort
(Nextcloud: `https://<cloud>/remote.php/dav/addressbooks/users/<user>/<book>/`). Seine
Kontakte siehst nur du, und sie gehen den globalen Telefonbüchern vor. Es wird im
Hintergrund abgeglichen; die Seite zeigt die Zahl der Kontakte oder den letzten Fehler.

### Dieses Gerät

Mit dem Panel-Recht findest du hier **Bildschirm wach halten, solange das Panel offen ist** —
etwa für ein Tablet an der Wand. Es gilt nur für den Browser, in dem du es anhakst (dein
Büro-PC bleibt, wie er ist). Nötig sind HTTPS und ein Browser, der das kann: Safari ab iOS
16.4 (als Home-Bildschirm-App ab iOS 18.4), Chrome, Edge. Kann deiner es nicht, sagt die Seite
das.

### Eigene Kurzwahlen

Mit dem Recht *Eigene Kurzwahlen anlegen* (lizenzierte Version) pflegst du hier deine
**eigenen** Kurzwahl-Kacheln — dieselbe Tabelle wie beim Admin (samt **Direkt wählen**): **Nummer** und **Name** je
Zeile, die leere Zeile am Ende fügt eine hinzu, der **Papierkorb** am Zeilenende löscht sie (mit Rückfrage). Nur du siehst sie im
Panel, nach den Nebenstellen zusammen mit den globalen Kurzwahlen (mit einer Person statt des
Sterns); sie verhalten sich wie jede Kurzwahl-Kachel. Eine Nummer, die schon globale Kurzwahl
ist, erscheint nur einmal. Auch ein Admin kann deine Liste einsehen und ändern.

---

## Verwaltung

Benutzer mit mindestens einem Admin-Recht bekommen ein **Zahnrad**-Symbol in der Kopfzeile.
Es öffnet den ersten Verwaltungsbereich, den sie nutzen dürfen; Reiter oben wechseln
zwischen **Einstellungen**, **Benutzer & Rollen**, **Nebenstellen**, **Telefonbücher**,
**Kurzwahlen** und **Protokoll** — jeder Reiter nur mit seinem Recht (*Einstellungen* für
Einstellungen, Nebenstellen, Telefonbücher und Kurzwahlen). **Zurück** bringt dich auf diesen Seiten (und auf deiner
Kontoseite) zur Seite, von der du kamst — Journal, Panel, Statistik oder Kosten.

### Einstellungen

*Recht Einstellungen.*

- **Logo & App-Icon** — lade dein eigenes **Logo** (PNG) und **Icon** für den Browser-Tab
  (PNG oder ICO) hoch, um die App zu branden. Das Logo erscheint in der Kopfzeile und auf
  der Anmeldeseite; ohne Upload gilt das eingebaute Symbol. Max. 2 MB je Datei; beides
  lässt sich jederzeit auf die Vorgabe zurücksetzen.
- **Ignorierte Anrufe (Kontexte & Nummern)** — welche Dialplan-Kontexte und gewählten
  Nummern im Journal ausgeblendet werden (eine Regel pro Zeile; wird nach `journal.hide`
  zurückgeschrieben). Neue Anrufe folgen sofort; für bestehende danach den Cache neu
  aufbauen.
- **Kosten / Tarife (costs.yaml)** — der Zustand der Tarifdatei: Ämter mit geladenem Tarif,
  Fehler und Warnungen. **Konfig prüfen** liest die `costs.yaml` neu ein und zeigt Fehler
  sofort, ohne Neustart (siehe [COSTS.md](COSTS.md)).
- **Codec-Erfassung (AMI)** — nur, wenn eingeschaltet: ob der Listener verbunden ist, seit
  wann und warum er getrennt ist, oder dass er keine Lebenszeichen mehr sendet (dann den
  Container `cdrj-ami` prüfen).
- **Anruf-Cache neu aufbauen** — das Journal neu aus den Daten der Telefonanlage ableiten.
  Benutzer und Einstellungen bleiben erhalten. Nötig nach einem Update, das die
  Rekonstruktionslogik geändert hat, oder nach dem Aktivieren einer Lizenz auf einer bisher
  freien Instanz. (Entspricht `./reset-cache.sh` auf dem Host.)

### Benutzer & Rollen

*Recht Benutzer und Rollen.*

Wer was darf, wird in **Rollen** festgelegt. Eine Rolle hat einen Namen, eine optionale
**OIDC-Gruppe** und eine Liste von **Rechten**.

- **Rechte werden nur addiert.** Wer mehrere Rollen hat, bekommt die Summe ihrer Rechte; ein
  „Verbieten" gibt es nicht.
- Die eingebaute Rolle **Benutzer** gilt für **alle Angemeldeten** und kann nicht gelöscht
  werden. Ab Werk hat sie *Journal: alle Anrufe*, *Export (CSV/PDF)*, *Kosten sehen* und
  *Statistik*. Änderst du sie, änderst du, was alle dürfen.
- Jede andere Rolle bekommen SSO-Benutzer über ihre **OIDC-Gruppe** bei der Anmeldung
  (Groß-/Kleinschreibung egal), **lokale Benutzer** durch Anhaken auf ihrer Benutzerseite.
  Eine geänderte Gruppen-Zuordnung wirkt ab der nächsten Anmeldung; geänderte Rechte einer
  Rolle — und bei lokalen Benutzern angehakte Rollen — wirken sofort (ein offenes Panel lädt
  sich binnen etwa zehn Sekunden neu, damit Knöpfe und Menüs passen).
- **Superadmins** dürfen ohne jede Rolle alles: Mitglieder von `auth.oidc.admin_groups` und
  die **Notzugänge** aus der Konfiguration (`auth.local.superadmin`). So kannst du dich beim Einrichten der Rollen nie selbst
  aussperren. Die eingebaute Rolle **Superadmin** (nicht löschbar) gewährt nichts — sie legt
  nur fest, was Superadmins **im Panel sehen** (Vorgabe: alles).
- Rechte, die ein späteres Update hinzufügt, starten in jeder Rolle **nicht angekreuzt** und
  sind als **neu** markiert — ein Update gewährt nie still etwas.
- Rechte der lizenzierten Version sind als **lizenzierte Version** markiert: Sie lassen sich
  ankreuzen, wirken aber nur mit gültiger Lizenz.

**Sichtbarkeit im Panel.** Jede Rolle kann eingrenzen, welche **Nebenstellen**, **Queues**,
**Ämter** (nach Name) und **Kurzwahlen** (nach Nummer, wie eingetragen) sie im
[Operator-Panel](#operator-panel) sieht: eine Kommaliste
aus Nummern (`21`), Bereichen (`20-59`) und Präfixen (`7*`); leer heißt alle. Ein
vorangestelltes Minus **schließt aus**: `-23,-24` zeigt alles außer 23 und 24, `20-29,-23`
zeigt 20–29 ohne 23 (auch `-20-29`, `-7*`). Mehrere Rollen werden zusammengezählt (was eine
davon zeigt, ist sichtbar), und jeder sieht immer seine eigenen Nebenstellen. Für
Superadmins zählt nur die Rolle **Superadmin**.

**Reiter Benutzer.** SSO-Konten erscheinen nach ihrer ersten Anmeldung. Öffne einen Benutzer,
um seine Rollen und OIDC-Gruppen aus der letzten Anmeldung zu sehen und ihm seine **eigenen
Nebenstellen** zuzuweisen — auch virtuelle wie eine Voicemail-Box. Ein Benutzer mit *nur
eigene Anrufe* und ohne Nebenstelle sieht keine Anrufe. **Benutzer löschen** entfernt das
Konto samt Nebenstellen und persönlichen Einstellungen; entferne einen SSO-Benutzer zuerst in
deinem Identity-Provider, sonst legt die nächste Anmeldung das Konto neu an. Dein eigenes
Konto kannst du nicht löschen. Löschen meldet den Benutzer sofort ab.

**Lokale Benutzer.** **+ Neuer Benutzer** legt ein Konto an, das sich ohne SSO anmeldet:
**Login-Name**, **Name**, **E-Mail** (optional, nötig für *Passwort vergessen*) und
**Passwort** (es gelten die Regeln aus der Konfiguration), dazu die **Rollen** zum Anhaken —
lokale Benutzer haben keine OIDC-Gruppen. Auf der Seite eines lokalen Benutzers gibt es
**Benutzer ändern** mit denselben Feldern; ein leeres Passwortfeld lässt das Passwort, wie es
ist. Ein vom Admin neu gesetztes Passwort meldet den Benutzer überall ab. Login-Name und
E-Mail müssen eindeutig sein und dürfen keinem Notzugang gehören. Meldet sich ein lokaler
Benutzer später per SSO mit **derselben E-Mail** an, wird das Konto auf OIDC umgestellt: das
lokale Passwort entfällt, die Rollen kommen dann aus den Gruppen des IdP. **Notzugänge**
(als solche gekennzeichnet) stammen aus der Konfigurationsdatei und sind hier nicht änderbar.

#### Rechte

In der Reihenfolge der Rollenseite. *L* = nur lizenzierte Version.

| Bereich | Recht | Was es erlaubt |
|---|---|---|
| Journal | Journal: nur eigene Anrufe | Liste, Kosten und Statistik zeigen nur Anrufe, an denen eine der **eigenen Nebenstellen** des Benutzers beteiligt war. |
| | Journal: alle Anrufe | Alle Anrufe der Anlage. |
| | Export (CSV/PDF) | Exporte von Journal, Kosten und Statistik — im Umfang der Journal-Rechte. |
| | Kosten sehen | Kostenspalten, die Kostenseite und Kosten im Ausdruck. |
| | Technische Details | Cause-Nummer, Dialplan-Kontext, SIP-Call-ID und Adressen in den Anrufdetails. |
| Statistik | Statistik | Die Statistik-Seite — im Umfang der Journal-Rechte. |
| Operator-Panel *(L)* | Panel öffnen | Das Panel mit den sichtbaren Nebenstellen, Queues und Ämtern; Agents pausieren sich und melden sich selbst an/ab. |
| | Wählen | Vom eigenen Arbeitsplatz aus wählen, Konferenzräumen beitreten. |
| | Eigene Gespräche steuern | Auflegen, übergeben, Rückfrage, parken, zu mir holen, in Konferenz überführen — an den eigenen Nebenstellen. |
| | Fremde Gespräche steuern | Zu mir holen, übergeben, parken, auflegen und umleiten an sichtbaren fremden Nebenstellen, Ämtern und Queues. |
| | Heranholen (Pickup) | Einen klingelnden Anruf einer sichtbaren Nebenstelle heranholen. |
| | Mithören / Flüstern / Aufschalten (Barge) | Je ein eigenes Recht. Wird immer protokolliert — rechtliche Lage beachten. |
| | Queues steuern | Agents pausieren und an- oder abmelden. |
| | Konferenzen steuern | Teilnehmer stummschalten oder hinauswerfen, Räume sperren und beenden; als Leiter beitreten; Anrufer ohne PIN-Abfrage in PIN-Räume holen. |
| | Follow-Me eigene / fremde Nebenstellen schalten | Zwei Rechte. |
| | Nicht stören eigene / fremde Nebenstellen schalten | Zwei Rechte. |
| | Telefon fernsteuern (annehmen, halten) | Am eigenen Tischtelefon annehmen, halten und zurückholen, sobald eine Telefonsteuerung eingerichtet ist. |
| | Eigene Kurzwahlen anlegen | Persönliche Kurzwahl-Kacheln unter *Konto*, die nur du siehst. |
| Voicemail *(L)* | Eigene / Fremde / Gruppen-Voicemail | Nachrichten anhören, markieren, weiterleiten und löschen — siehe [Voicemail](#voicemail). |
| Aufnahmen *(L)* | Eigene / Fremde / Queue-Aufnahmen anhören / herunterladen / löschen | Neun Rechte — siehe [Aufnahmen](#aufnahmen). Löschen wird immer protokolliert. |
| | Eigene Gespräche aufnehmen / Fremde Gespräche aufnehmen | Aufnahmen im Panel starten und beenden. |
| Telefonbücher *(L)* | Globale Telefonbücher sehen | Namen aus LDAP, CardDAV und Contact Manager; Kontakt-Seitenleiste; Vorschläge. |
| | Eigene Telefonbücher anlegen/sehen | Ein eigenes CardDAV-Adressbuch einbinden. |
| Verwaltung | Einstellungen | Die Reiter Einstellungen, Nebenstellen, Telefonbücher und Kurzwahlen; Admin-Warnmails. |
| | Benutzer und Rollen | Rollen, Rechte und die Nebenstellen der Benutzer. Wer es hat, kann sich alles selbst geben — vergib es mit Bedacht. |
| | Protokoll | Das [Protokoll](#protokoll). |
| Konto | Passwort vergessen (lokale Benutzer) | *Passwort vergessen?* auf der Anmeldeseite schickt dem Benutzer einen Link zum Neusetzen (braucht eine E-Mail-Adresse am Konto und eingerichteten Mailversand). |

### Nebenstellen

*Recht Einstellungen.* Alles rund um die Nebenstellen, wie das Panel sie nutzt:

- **Pausengründe (Queues)** — die feste Auswahl, die ein Agent beim Pausieren bekommt (einer
  pro Zeile; *ohne Grund* steht immer zur Wahl).
- **Auto-Answer-Vorlagen** — der SIP-Header, den das Panel an dein eigenes Telefon schickt,
  damit es von selbst abhebt, wenn du aus dem Panel wählst, eine Vorlage pro
  Telefonhersteller (*Call-Info* passt für Yealink, Snom, Grandstream und Fanvil). Eine
  Vorlage ist die **Vorgabe für alle übrigen**.
- **Je Nebenstelle:** welche Vorlage gilt (oder *aus* bei Telefonen, die kein Auto-Answer
  können), **nicht mithörbar** (das Panel bietet an dieser Nebenstelle nie Mithören,
  Flüstern oder Aufschalten an — z. B. Geschäftsführung, Betriebsrat) und die Spalte
  **Telefon** für die Telefonsteuerung.
- **Telefonsteuerung** — der Telefon-Knopf (grau = nicht eingerichtet, grün = eingerichtet)
  öffnet *Telefonsteuerung einrichten*: die gerade an der Nebenstelle angemeldeten Geräte
  mit Adresse und vorgeschlagener Telefonart; **Übernehmen** füllt einen Eintrag aus, du
  ergänzt das Token oder Passwort (Augen-Knopf zum Anzeigen). Telefonarten: *Yealink (über
  die Telefonanlage)* (nichts einzutragen), *Auerswald COMfortel D-Serie* (Adresse + Token)
  und *Auerswald COMfortel 1400/2600/3600 IP* (Adresse + Web-Login; nur Annehmen).
  Einstellungen am Telefon: [CONFIGURATION.md → Phone control](CONFIGURATION.md#phone-control-answer-and-hold-from-the-panel-licensed-version).
- **Konferenzräume zum Überführen** — *Von Raum* / *Bis Raum*: die FreePBX-Konferenzräume,
  die *In Konferenz überführen* nutzen darf (leer = Knopf aus).

### Telefonbücher

*Recht Einstellungen, lizenzierte Version.* Die globalen Telefonbücher: Land und
Ortsvorwahl (damit Nummern vergleichbar werden), das Abgleich-Intervall und die Quellen
**LDAP**, **CardDAV** und **FreePBX Contact Manager** — jede mit **Verbindung testen**,
ihrer Kontaktzahl oder dem letzten Fehler und **Jetzt abgleichen**. Ebenfalls hier:
**CallerID Superfecta**, das die Namen aus den Telefonbüchern auf den Displays der Telefone
anzeigt. Feld für Feld:
[CONFIGURATION.md → Phone books](CONFIGURATION.md#phone-books-licensed-version).

### Kurzwahlen

*Recht Einstellungen.* Kacheln für wichtige Nummern im Panel, in zwei Bereichen:

- **Globale Kurzwahlen** — für alle: eine Zeile je Eintrag mit **Nummer** (extern, z. B.
  `+49 221 123456`, oder intern, z. B. `666`; Ziffern, `*`, `#`, vorne ein `+`) und **Name**.
  Die leere Zeile am Ende fügt einen hinzu; der **Papierkorb** am Zeilenende löscht ihn (mit Rückfrage). Welche
  Kurzwahlen eine Rolle sieht, legt ihr Feld *Kurzwahlen (Nummer)* fest (siehe
  [Benutzer & Rollen](#benutzer--rollen)). Die Spalte **Anlage** zeigt, ob es die Nummer in
  der Anlage gibt (*intern*: Nebenstelle, Hint oder Dialplan — die Kachel zeigt deren
  Zustand) oder nicht (*extern*: die Kachel leuchtet bei Gesprächen mit ihr); *–* = noch
  nicht geprüft (neue Nummern werden binnen einer halben Minute nachgeschlagen). **Direkt
  wählen** lässt einen Klick auf die Kachel ohne Nachfrage wählen — praktisch für einen
  Türöffner wie `*833`.
- **Persönliche Kurzwahlen** — die eigenen Kurzwahlen eines Benutzers (siehe
  [Eigene Kurzwahlen](#eigene-kurzwahlen)). Benutzer wählen (die Zahl hinter dem Namen ist
  die Anzahl seiner Kurzwahlen) und die Liste genauso bearbeiten. Im Panel des Benutzers
  erscheinen sie nur, solange eine seiner Rollen das Recht *Eigene Kurzwahlen anlegen* hat —
  sonst weist die Seite darauf hin.

Änderungen stehen im Protokoll.

### Protokoll

*Recht Protokoll.* Sicherheitsrelevante Handlungen mit Zeit, Benutzer, Ziel und IP: Rollen-
und Rechteänderungen, zugewiesene oder entfernte Nebenstellen, gelöschte Benutzer,
Änderungen an Einstellungen (Ausblende-Regeln, Branding, Kosten-Prüfung, Cache-Neuaufbau,
Nebenstellen, Telefonbücher, Telefonsteuerung), **abgewiesene Anmeldungen** (der
eingegebene Name, nie das Passwort) — und jede Aktion im Panel: Wählen, Übergaben,
Heranholen, Mithören, Voicemail und Aufnahmen (anhören, herunterladen, löschen, starten,
beenden), Nicht stören / Follow-Me, Queue- und Konferenzsteuerung, Telefonsteuerung. Oben
nach Aktion filtern. Einträge älter als ein Jahr werden entfernt.

---

## Tipps

- Ansichten lassen sich teilen: Kopier die URL, um einem Kollegen genau das gefilterte
  Ergebnis zu geben.
- Nutze **Tabelle maximieren** an einem Wanddisplay oder beim Durchsehen einer langen Liste.
- Die Spalte **Beteiligt** und die Suche mit `#<nst>` sind der schnellste Weg zur Antwort
  auf „Was war heute auf Nebenstelle N los?".
