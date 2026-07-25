# Raum-Zentrale v1.1 · Spvgg Warmbronn

## Was geändert wurde

- Nach der Anmeldung öffnet sich jetzt direkt **„Neuen Termin eintragen“**.
- Sobald Datum und Uhrzeit eingegeben oder geändert werden, prüft die Seite automatisch **beide Räume**.
- Der gewünschte Raum wird als **frei** oder **belegt** angezeigt.
- Ist der große Saal belegt und der kleine Raum frei, erscheint direkt eine Schaltfläche **„Alternative übernehmen“**.
- Sind beide Räume belegt, bleibt die Buchung gesperrt und die Uhrzeit muss geändert werden.
- Die Datenbank verhindert zusätzlich weiterhin echte Doppelbuchungen, auch wenn zwei Personen gleichzeitig speichern.

## Eigenständige Zugänge

Es gibt keine persönlichen Nutzerkonten und keine Verknüpfung zwischen mehreren Funktionen.
Jeder Zugang bucht immer ausschließlich unter seiner eigenen Funktion:

### Vereinsführung
- Vorstand
- Geschäftsstelle

### Fußball
- Fußball · Abteilungsleitung
- Fußball · Jugendleitung

### Weitere Abteilungen
- Aktiv & Gesund
- Mountainbike
- Kinder- & Jugendsport
- Tischtennis
- Volleyball & Badminton
- Chor & Gesang

### Gaststätte
- Gaststätte 1910

Standard-PIN neuer Zugänge: **1910**. Jede PIN ist getrennt änderbar.

## Aktualisierung auf GitHub

Im Repository `raumbelegung` die bisherige Datei `index.html` durch die neue Datei ersetzen und den Commit bestätigen.

Die Seite bleibt erreichbar unter:

`https://spvgg-warmbronn.github.io/raumbelegung/`

## Supabase aktualisieren

### Die alte SQL-Datei wurde bereits ausgeführt

Im Supabase SQL Editor nur diese Datei ausführen:

`supabase_update_v1_1.sql`

Vorhandene Buchungen und bereits geänderte PINs bleiben erhalten. Der bisherige Zugang `Fußball` wird zur `Fußball · Abteilungsleitung`, damit seine alten Buchungen nicht verloren gehen.

### Die Raum-Zentrale wurde noch nie in Supabase eingerichtet

Stattdessen die vollständige Datei ausführen:

`supabase_raumbelegung_setup.sql`

## Wichtig

Die HTML-Datei allein zeigt die neue Oberfläche. Die beiden neuen Zugänge `Geschäftsstelle` und `Fußball · Jugendleitung` erscheinen erst, nachdem auch das SQL-Update in Supabase ausgeführt wurde.
