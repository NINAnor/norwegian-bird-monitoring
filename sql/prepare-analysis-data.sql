/*
===============================================================================
Norwegian Bird Monitoring
prepare-analysis-data.sql

Purpose
-------
Prepares the quality-assured analysis and export dataset used in the
Norwegian Bird Monitoring programme.

The workflow creates the route-year-species combinations used as input
for population trend analyses and other data deliveries.

Main steps
----------
- prepares route/year combinations
- applies quality-assurance criteria
- excludes the first surveyed year for each route
- combines point-count and line-transect observations
- prepares data for downstream TRIM/RTRIM analyses and data exports

Database
--------
TOVTaksering (Microsoft SQL Server)

Important
---------
This script modifies and rebuilds analysis tables. It should only be run
against the intended project database after the annual quality assurance
process has been completed.

External analysis software such as RTRIM/rtrim-shell is not included in
this repository.

Documentation
-------------
See:
Vang et al. 2023. Norsk hekkefuglovervåking systemdokumentasjon.
NINA Report 2230.

Maintained by
-------------
Norwegian Institute for Nature Research (NINA)
https://www.nina.no/

===============================================================================
*/
/*
	Birdstat - årlig klargjøring av analyse- og eksportgrunnlag
	Script for å generere tabeller som brukes som grunnlag for statistikk, analyser og dataleveranser. Bruksområde:

	1. TRIM-analyser
	2. Birdstat-analyser
	3. Dataleveranser til GBIF/Artskart

	--Kriterier for godkjenning av data TOV-E for uttrekk til statistikk.

--1.	Det skal bare inkluderes data for Gjeldende pkt. WHERE KodeEndring <> 9
--2.	Første år besøkt inkluderes ikke, men alle år deretter med godkjente verdier for kvalitetssikring inkluderes. Ligger i egen tabell sammen med verifiseringsinformasjon.
--3.	Tid/Vær verifisering skal være Godkjent
--4.	Punktverifisering skal ha verdi Godkjent.
--5.	Linjeverifisering skal ha verdi Godkjent.
--6.	OKDatoKl 2005-2008 (tilsvarer Tid/Vær verifisering over) data skal ha verdi 1.
--7.	Pkt inkludert 2005-2008 (tilsvarer Tid/Vær verifisering over) skal ha verdi 1.

--TOV-I data skal spørre etter summert antall <50 + > 50 + Linjetaksdata (bare arter 'Ikke spurvefugl' og 'obligatoriske spurvefugl').
--Totalfila skal også inkludere data fra HFT og TOV-I.
--TOV-I data lastes inn i TOV-E-databasen fra en separat importtabell.
--Startår for data er 1995 - Det skal legges inn verdier (-1) for alle år med manglende taksering eller ikke godkjent data for alle år i tidsserien 1995-2009.
--Artsvise analysefiler genereres i et standardisert oppsett i neste ledd av arbeidsflyten.
--For ruter som har bare ett godkjent år, skal ruta utelates

*/
/********************************************************************************************************************/ 

-- VIKTIG VED ÅRLIG KJØRING:
--  * @CurrentYear nedenfor er den eneste årsparameteren som skal endres.
--  * TrimSites og TrimResults tømmes og bygges opp på nytt. Kjør etter ordinær databasebackup.
--  * Taksering/Count = -1 betyr manglende eller utelatt data. 0 betyr godkjent taksering uten observasjon av aktuell art.
--  * Scriptet forutsetter at underliggende tabeller og views har samme struktur som dokumentert for prosjektet.

USE [TOVTaksering];
SET NOCOUNT ON;

--1. Sett gjeldende år
DECLARE @CurrentYear SMALLINT,
        @PreviousYear SMALLINT,
        @Sql NVARCHAR(MAX);

SET @CurrentYear = 2026;
SET @PreviousYear = @CurrentYear - 1;


-- 2. Bevar snapshot av forrige års produksjonsgrunnlag.
-- Opprettes bare ved første kjøring. Eksisterende snapshot-tabeller
-- beholdes uendret ved omkjøring.
-- SELECT INTO kopierer data og kolonnestruktur, men ikke indekser/constraints.

    IF OBJECT_ID(
        N'dbo.TrimResults_' + CONVERT(nvarchar(4), @PreviousYear),
        N'U'
    ) IS NULL
    BEGIN
        SET @Sql =
            N'SELECT * INTO [dbo].[TrimResults_'
            + CONVERT(nvarchar(4), @PreviousYear)
            + N'] FROM [dbo].[TrimResults];';

        EXEC sys.sp_executesql @Sql;
    END;

    IF OBJECT_ID(
        N'dbo.TrimSites_' + CONVERT(nvarchar(4), @PreviousYear),
        N'U'
    ) IS NULL
    BEGIN
        SET @Sql =
            N'SELECT * INTO [dbo].[TrimSites_'
            + CONVERT(nvarchar(4), @PreviousYear)
            + N'] FROM [dbo].[TrimSites];';

        EXEC sys.sp_executesql @Sql;
    END;

  

--3. Tøm arbeids-/resultattabellene. OBS: Dette sletter ALLE rader i tabellene.
DELETE FROM TrimSites;
DELETE FROM TrimResults;


-- Aktive/gjeldende ruter avledes fra PktPlassering (KodeEndring <> 9).
--4. Legg inn nytt år i tabellen TrimYears
IF NOT EXISTS (SELECT 1 FROM [dbo].[TrimYears] WHERE [TrimYear] = @CurrentYear)
    INSERT INTO [dbo].[TrimYears] ([TrimYear]) VALUES (@CurrentYear);
--5. Legg til i tabell Trimsites via cursor loop
declare @RuteID smallint

DECLARE route_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT RuteID FROM PktPlassering WHERE KodeEndring <> 9
OPEN route_cursor
FETCH route_cursor INTO @RuteId

WHILE @@FETCH_STATUS = 0
	BEGIN	
		INSERT INTO [TOVTaksering].[dbo].[TrimSites]
			   ([RuteID]
			   ,[Year]
			   ,Taksering)   
		SELECT @RuteId, TrimYear,-1  FROM TrimYears 
		FETCH route_cursor INTO @RuteId
	END
CLOSE route_cursor
DEALLOCATE route_cursor

---------------------------------------------------------------------
--6. Legg inn kode 0 på de år som eksisterer i RuteVerifisertStatus
update TRIMSites set Taksering=0
FROM         RuteVerifisertStatus INNER JOIN
                      TrimSites ON RuteVerifisertStatus.FK_RuteID = TrimSites.RuteID AND 
					  RuteVerifisertStatus.Aar = TrimSites.Year


---------------------------------------------------------------------
--7.Første år besøkt inkluderes ikke, men alle år deretter med godkjente verdier for kvalitetssikring inkluderes. 
-- Erstatter cursoren med en samlet UPDATE for å redusere kjøretiden.
-- Første takseringsår beregnes per rute i stedet for per rad i TrimSites.
-- Eksisterende logikk beholdes: Taksering settes til -1 for første registrerte takseringsår og tidligere år. 
-- Manglende år erstattes med @CurrentYear. 

;WITH ForsteTakseringsaar AS
(
    SELECT
        FK_RuteID,
        MIN(Aar) AS ForsteAar
    FROM dbo.PunktTaksering_Normalisert
    GROUP BY FK_RuteID
)
UPDATE S
        SET S.Taksering = -1
        FROM dbo.TrimSites AS S
        LEFT JOIN ForsteTakseringsaar AS F
            ON F.FK_RuteID = S.RuteID
        WHERE ISNULL(F.ForsteAar, @CurrentYear) >= S.[Year];



--select count(*) from TRIMSites where Taksering <> -1
---------------------------------------------------------------------
--3.	Tid/Vær verifisering skal være Godkjent
--4.	Punktverifisering skal ha verdi Godkjent.
--5.	Linjeverifisering skal ha verdi Godkjent.
--6.	OKDatoKl 2005-2008 (tilsvarer Tid/Vær verifisering over) data skal ha verdi 1.
--7.	Pkt inkludert 2005-2008 (tilsvarer Tid/Vær verifisering over) skal ha verdi 1.

--8. Ruter som ikke er godkjente
update TRIMSites set Taksering=-1
FROM         TrimSites INNER JOIN
                      RuteVerifisertStatus ON TrimSites.Year = RuteVerifisertStatus.Aar AND TrimSites.RuteID = RuteVerifisertStatus.FK_RuteID
WHERE     (isnull(RuteVerifisertStatus.PunktGodkjent,0) <> 1) OR (ISNULL(RuteVerifisertStatus.DatoKlGodkjent, 0) <> 1) OR (ISNULL(RuteVerifisertStatus.LinjeGodkjent, 0) <> 1)

--9. Ruter som er godkjente, men ikke taksert
update TRIMSites set Taksering=-1
FROM         TrimSites INNER JOIN
                      RuteVerifisertStatus ON TrimSites.Year = RuteVerifisertStatus.Aar AND TrimSites.RuteID = RuteVerifisertStatus.FK_RuteID
WHERE     (isnull(RuteVerifisertStatus.IkkeTaksert,0) = 1)


-- 10. For ruter som har bare ett godkjent år, skal ruta utelates
-- Oppdater til -1 dersom "Taksering <> -1"
UPDATE TRIMSites set Taksering=-1
where ruteid in (
	select ruteid as antall from TRIMSites where Taksering <> -1
	group by ruteid having count(*) = 1)


/* ============================================================================
   11. Opprett TrimResults for alle ruter, år og relevante arter

   Det opprettes én rad per kombinasjon av:
       - rute
       - år
       - art

   Artslisten består av:
       1) arter som finnes i punkttakseringene
       2) arter som finnes i linjetakseringene og er definert som linjetaksart

   UNION sørger for at en art som finnes i begge datakildene bare tas med én gang.

   Count settes innledningsvis lik Taksering fra TrimSites:
       -1 = ruta/året skal ikke inngå i analysen
        0 = godkjent rute/år uten registrert art

   Observerte antall legges på i de etterfølgende stegene.
   ============================================================================ */

;WITH Species AS
(
    -- Arter som finnes i punkttakseringene
    SELECT P.Art AS SpeciesID
    FROM dbo.PunktTaksering_Normalisert AS P
    WHERE P.Art IS NOT NULL

    UNION

    -- Arter som bare eller også kan forekomme i linjetakseringene
    SELECT L.FK_ArtsID AS SpeciesID
    FROM dbo.Linjetaksering_Normalisert AS L
    INNER JOIN dbo.Art AS A
        ON A.ArtsID = L.FK_ArtsID
    WHERE L.FK_ArtsID IS NOT NULL
      AND A.Linjetaksart = 1
)

INSERT INTO dbo.TrimResults
(
    Site,
    [Year],
    Species,
    [Count],
    Dataset
)
SELECT
    T.RuteID,
    T.[Year],
    S.SpeciesID,
    T.Taksering,
    'TOV-E'
FROM dbo.TrimSites AS T
CROSS JOIN Species AS S;

---------------------------------------------------------------------
--12. Oppdater antall observasjoner.
-- Forutsetning: kilde-viewene gir entydig rad per rute/år/art for oppdateringene nedenfor.
-- Verifiser også at Art.FK_Kode_Flokk bare inneholder forventede kodeverdier (1, 2 eller 3).

--a. Punkttaksering
--Spør mot view RuteTaksering_Normalisert_Filtered_KodeEndring (KodeEndring IN (0, 1, 2,3,4))
Update [TrimResults]
		set Count= isnull(R.AntallU50,0) + isnull(R.AntallO50,0) +
		CASE Art.FK_Kode_Flokk -- Regn om fra flokk
			WHEN 1 THEN Ceiling(convert(float,isnull(R.AntallFlokk,0)/5.0))
			WHEN 2 THEN Ceiling(convert(float,isnull(R.AntallFlokk,0)/2.0))
			WHEN 3 THEN 0
		END
		,DatoEndret=R.DatoEndret
FROM  RuteTaksering_Normalisert_Filtered_KodeEndring R INNER JOIN
          TrimResults ON R.FK_RuteID = TrimResults.Site AND R.Aar = TrimResults.Year AND 
          R.Art = TrimResults.Species INNER JOIN
                      Art ON R.Art = Art.ArtsID
     WHERE TrimResults.Count <> -1


--b. Linjetaksering
Update [TrimResults]
		set Count= Count + ISNULL(Linjetaksering_Normalisert.Antall, 0) +
		CASE Art.FK_Kode_Flokk -- Regn om fra flokk
			WHEN 1 THEN Ceiling(convert(float,isnull(Linjetaksering_Normalisert.AntallFlokk,0)/5.0))
			WHEN 2 THEN Ceiling(convert(float,isnull(Linjetaksering_Normalisert.AntallFlokk,0)/2.0))
			WHEN 3 THEN 0
		END	
FROM         TrimResults INNER JOIN
                      Linjetaksering_Normalisert ON TrimResults.Species = Linjetaksering_Normalisert.FK_ArtsID AND TrimResults.Site = Linjetaksering_Normalisert.RuteID AND 
                      TrimResults.Year = Linjetaksering_Normalisert.Aar1 INNER JOIN
                      Art ON Linjetaksering_Normalisert.FK_ArtsID = Art.ArtsID
WHERE     (TrimResults.Count <> -1) AND Art.Linjetaksart=1

--13. Oppdater DatoEndret
Update [TrimResults]
		set DatoEndret= Linjetaksering_Normalisert.DatoEndret
FROM         TrimResults INNER JOIN
                      Linjetaksering_Normalisert ON TrimResults.Species = Linjetaksering_Normalisert.FK_ArtsID AND TrimResults.Site = Linjetaksering_Normalisert.RuteID AND 
                      TrimResults.Year = Linjetaksering_Normalisert.Aar1 
WHERE     (TrimResults.Count <> -1)  and [TrimResults].DatoEndret IS NULL


 --14. Generer unik ID for observasjonen.
 -- Formatet forutsetter fire sifre for år og maks fire sifre for Site/Species.
 -- Endring av ID-format må avklares mot nedstrøms bruk (f.eks. GBIF/catalogNumber).
 UPDATE [TrimResults] Set TrimId=convert(varchar(4), [Year]) + right('0' +convert(varchar(4), [Site]),4) + convert(varchar(4), [Species])


 
 
 ---SLUTT Kjøring Norsk hekkefuglovervåking

--15. EKSTRA HFT:
--Legg inn gjeldende år i HFT-data
INSERT INTO [TOVTaksering].[dbo].ImportData_HFT
           ([Site]
           ,[Year]
           ,[Count]
           ,[Species]
           ,[Dataset])
  SELECT DISTINCT src.Site, @CurrentYear, -1, src.Species, 'HFT'
  FROM [TOVTaksering].[dbo].ImportData_HFT AS src
  WHERE NOT EXISTS (
      SELECT 1
      FROM [TOVTaksering].[dbo].ImportData_HFT AS existing
      WHERE existing.Site = src.Site
        AND existing.[Year] = @CurrentYear
        AND existing.Species = src.Species
        AND existing.Dataset = 'HFT'
  );


--16. EKSTRA TOV-I  		
--Legg til gjeldende år for de arter som er observert på ruta annet år:		
declare @Species int,
		@Rutenr int
		
DECLARE tovi_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT Rutenr, Species FROM TOVTaksering.dbo.ImportData_TOVI ORDER BY Rutenr, Species
OPEN tovi_cursor
FETCH tovi_cursor INTO @Rutenr, @Species
declare @exists int

WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @exists = COUNT(*)
		FROM TOVTaksering.dbo.ImportData_TOVI
		WHERE Rutenr = @Rutenr
		  AND Species = @Species
		  AND År = @CurrentYear;

		IF @exists = 0
			INSERT INTO ImportData_TOVI (År, Rutenr, Ant, Species, DateModified, Comment)
			VALUES (@CurrentYear, @Rutenr, 0, @Species, GETDATE(), 'Autogenerert av årlig Birdstat-script; art observert annet år');

		FETCH tovi_cursor INTO @Rutenr, @Species
	END
CLOSE tovi_cursor
DEALLOCATE tovi_cursor		

update ImportData_TOVI
set Ant=-1
where år=@CurrentYear

--17. AVKLARING: Kontroller om VIEW RuteGodkjentStatusAlleAarGrid krever manuell oppdatering for nytt år.
--SLUTT
