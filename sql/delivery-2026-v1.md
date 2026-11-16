# Kjørelogg – analysegrunnlag til og med 2026

## Kjøring
- Kjøredato og tidspunkt:
- Utført av: Roald Vang
- Database: TOVTaksering
- Skript: sql/prepare-analysis-data.sql
- Git-commit: 6d75292
- Tag: delivery-2026-v1
- Parameter: @CurrentYear = 2026
- Hele skriptet kjørt uten lokale endringer: nei
- Eventuelle avvik eller omkjøringer: Cursor-loop tok veldig lang tid, så skrev om denne.

## Datagrunnlag
- Kvalitetssikring avsluttet:
- Databasebackup eller bevart kildeuttrekk: [navn og lagringssted]
- Snapshot-tabeller fra forrige produksjon:
  dbo.TrimResults_2025 og dbo.TrimSites_2025

## Resultat og kontroll
- Antall rader i TrimResults:3591505
- Antall faktiske tellinger: 141119
- Antall ruter: 491
- Antall arter:229
- Første og siste dataår: 2006	2026
- Kontroller utført og eventuelle avvik: ingen
- SQL-feilmeldinger og oppfølging: Ingen

## Leveranse
- Genererte filer og lagringssted:
- Status: Under kontroll / Godkjent
- Kontrollert av og dato:

  				
