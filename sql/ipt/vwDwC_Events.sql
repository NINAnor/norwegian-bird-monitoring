-- D2 publication view, supplied 2026-11-25.
-- Reference definition for the existing production view; not a standalone deployment script.
-- Depends on dbo.vwDwC_Occurrence as well as operational source tables.
USE [TOVTaksering];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER VIEW [dbo].[vwDwC_Events]
AS
SELECT TOP (100) PERCENT
    dbo.Ruteinformasjon.eventID,
    'Event' AS [dcterms:type],
    'NINA/BIRDLIFE' AS ownerInstitutionCode,
    DATEFROMPARTS(dbo.Ruteinformasjon.Aar, dbo.Ruteinformasjon.Maaned, dbo.Ruteinformasjon.Dag) AS eventDate,
    CONVERT(varchar, dbo.Ruteinformasjon.StartKl) + '/' + CONVERT(varchar, dbo.Ruteinformasjon.StoppKl) AS eventTime,
    'https://hekkefuglovervakingen.nina.no/Fugl/public/papirskjema/MethodologyEng.pdf' AS samplingProtocol,
    ROUND(dbo.ASkjemaInfo.LengdeRute, 0) AS sampleSizeValue,
    'metre' AS sampleSizeUnit,
    'NO' AS countryCode,
    'Norwegian bird monitoring' AS datasetName,
    CONVERT(varchar, DATEDIFF(minute, CONVERT(time, dbo.Ruteinformasjon.StartKl), CONVERT(time, dbo.Ruteinformasjon.StoppKl)))
        + ' minutes/' + CONVERT(varchar, dbo.ASkjemaInfo.nPkt) + ' sampling points' AS samplingEffort,
    dbo.Ruteinformasjon.FK_RuteID AS locationID,
    'Norway' AS country,
    Komm.Region AS stateProvince,
    Komm.Kommune AS municipality,
    dbo.ASkjemaInfo.NavnRute AS locality,
    ROUND(dbo.ASkjemaInfo.RandomLat, 5) AS decimalLatitude,
    ROUND(dbo.ASkjemaInfo.RandomLong, 5) AS decimalLongitude,
    'EPSG:4326' AS geodeticDatum,
    5000 AS coordinateUncertaintyInMeters,
    dbo.ASkjemaInfo.Lavest AS minimumElevationInMeters,
    dbo.ASkjemaInfo.Hoyest AS maximumElevationInMeters,
    'Coordinates represent a displaced route centre, located between 1,000 and 5,000 metres from the original route centre. Exact counting-point coordinates are withheld to protect the monitoring sites.' AS dataGeneralizations,
    'Exact counting-point coordinates are withheld to protect the monitoring sites.Observers identity withheld due to GDPR restrictions' AS informationWithheld,
    dbo.Ruteinformasjon.Aar AS year,
    dbo.Ruteinformasjon.Maaned AS month,
    dbo.Ruteinformasjon.Dag AS day,
    CONVERT(VARCHAR(33), dbo.Ruteinformasjon.DatoEndret, 126) AS [dcterms:modified],
    'Exact location withheld to protect long-term study.' AS locationRemarks
FROM dbo.Ruteinformasjon
INNER JOIN dbo.ASkjemaInfo ON dbo.Ruteinformasjon.FK_RuteID = dbo.ASkjemaInfo.RUTENR
LEFT OUTER JOIN Metadata.dbo.Kommune AS Komm ON Komm.nr = dbo.ASkjemaInfo.Komid
INNER JOIN dbo.RuteVerifisertStatus ON dbo.Ruteinformasjon.Aar = dbo.RuteVerifisertStatus.Aar
    AND dbo.Ruteinformasjon.FK_RuteID = dbo.RuteVerifisertStatus.FK_RuteID
WHERE (ISNULL(dbo.RuteVerifisertStatus.PunktGodkjent, 0) = 1)
    AND (ISNULL(dbo.RuteVerifisertStatus.DatoKlGodkjent, 0) = 1)
    AND (ISNULL(dbo.RuteVerifisertStatus.LinjeGodkjent, 0) = 1)
    AND (ISNULL(dbo.RuteVerifisertStatus.IkkeTaksert, 0) <> 1)
    AND dbo.Ruteinformasjon.eventID IN (SELECT eventID FROM vwDwC_Occurrence);
GO
