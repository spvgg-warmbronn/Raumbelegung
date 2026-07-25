# Raum-Zentrale · Spvgg Warmbronn 1910 e.V.

## Enthaltene Dateien

- `raumbelegung.html` – die fertige zweite GitHub-Seite
- `supabase_raumbelegung_setup.sql` – einmalige Einrichtung der gemeinsamen Online-Datenbank

## Was die Anwendung kann

- Zugang für jede offizielle Abteilung bzw. jeden offiziellen Bereich
- eigener Zugang für **Gaststätte 1910**
- Gesamtzugang für **Vorstand / Geschäftsstelle**
- Standard-PIN bei der Ersteinrichtung: **1910**
- jede Abteilung kann ihre eigene PIN ändern
- Wochenkalender mit Uhrzeiten von 06:00 bis 24:00 Uhr
- Monatskalender mit Belegungsmarkierungen
- zwei getrennte Ressourcen:
  - Großer Versammlungsraum
  - Kleiner Raum
- direkte, verbindliche Buchung
- automatische Sperre gegen Doppelbelegungen
- Bearbeiten und Löschen durch die eintragende Abteilung
- Gesamtzugang kann alle Buchungen bearbeiten und löschen
- Export der eigenen kommenden Buchungen als `.ics`-Kalenderdatei

## Angelegte Zugänge

1. Fußball
2. Aktiv & Gesund
3. Mountainbike
4. Kinder- & Jugendsport
5. Tischtennis
6. Volleyball & Badminton
7. Chor & Gesang
8. Gaststätte 1910
9. Vorstand / Geschäftsstelle

## Schritt 1: Supabase einrichten

Die neue Seite nutzt dieselbe Supabase-Instanz wie die Jugend-Zentrale. Dadurch bleibt der Betrieb kostenlos und alle Nutzer sehen dieselben Buchungen.

1. Supabase öffnen.
2. Das bestehende Projekt der Jugend-Zentrale auswählen.
3. Links **SQL Editor** öffnen.
4. **New query** auswählen.
5. Den kompletten Inhalt von `supabase_raumbelegung_setup.sql` einfügen.
6. Auf **Run** klicken.
7. Es müssen die Tabellen `raum_zugaenge` und `raum_buchungen` angelegt sein.

Das SQL-Skript kann erneut ausgeführt werden. Bereits geänderte PINs werden dabei nicht wieder auf 1910 zurückgesetzt.

## Schritt 2: HTML bei GitHub hochladen

Nur die Datei `raumbelegung.html` muss in das öffentliche GitHub-Repository hochgeladen werden. Die SQL-Datei wird nicht für die Website benötigt.

1. Das GitHub-Repository öffnen, in dem bereits die bisherige `index.html` liegt.
2. **Add file** → **Upload files** auswählen.
3. `raumbelegung.html` hochladen.
4. **Commit changes** bestätigen.
5. Nach der Veröffentlichung liegt die Seite neben der bisherigen Hauptseite.

Beispiel:

```text
Bisherige Seite:
https://BENUTZERNAME.github.io/REPOSITORY/

Neue Raum-Zentrale:
https://BENUTZERNAME.github.io/REPOSITORY/raumbelegung.html
```

## Schritt 3: Erste Anmeldung

1. `raumbelegung.html` im Browser öffnen.
2. Abteilung auswählen.
3. Mit der Standard-PIN **1910** anmelden.
4. Unter **Einstellungen** sofort eine eigene Abteilungs-PIN festlegen.
5. Die neue PIN intern an die berechtigten Personen weitergeben.

## Optional: Link auf der bisherigen Startseite

In die vorhandene `index.html` kann beispielsweise dieser Link eingebaut werden:

```html
<a href="raumbelegung.html">Raum-Zentrale öffnen</a>
```

## Sicherheitsprinzip

Der im HTML sichtbare Supabase-`anon`-Schlüssel ist ein öffentlicher Browser-Schlüssel. Die Tabellen selbst sind für direkte Zugriffe gesperrt. Lesen, Speichern, Löschen und PIN-Änderungen laufen ausschließlich über die im SQL-Skript angelegten, PIN-geprüften Funktionen.

Wichtig: Niemals einen Supabase-`service_role`-Schlüssel in GitHub oder in eine HTML-Datei eintragen.

## Abgrenzung zur Platz-Funktion der Trainer-App

Übernommen wurden die sinnvollen Elemente der bisherigen Platzbelegung:

- Wochenwechsel
- zeitliche Kalenderansicht
- Ressourcenumschalter
- Konfliktprüfung
- Detailansicht
- Bearbeiten und Löschen

Nicht übernommen wurden sportplatzbezogene Funktionen wie Rasen/Kunstrasen, Platzhälften, Winterumlegung, Trainingszuordnung und Freigabeanfragen. Für die beiden Besprechungsräume ist eine direkte Buchung mit harter Doppelbelegungssperre übersichtlicher.
