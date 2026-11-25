-- D2 publication view, supplied 2026-11-25.
-- Reference definition for the existing production view; not a standalone deployment script.
-- Requires the operational database, its source tables and Metadata.dbo.Kommune.
USE [TOVTaksering];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER VIEW [dbo].[vwDwC_Occurrence]
AS
SELECT TOP (100) PERCENT
    'Occurrence' AS [dcterms:type],
    dbo.Ruteinformasjon.eventID,
    dbo.TrimResults.TrimId AS catalogNumber,
    'urn:catalog:NINA:TOV-E:' + CONVERT(varchar, dbo.TrimResults.TrimId) AS occurrenceID,
    'Norwegian bird monitoring' AS collectionCode,
    'HumanObservation' AS basisOfRecord,
    dbo.TrimResults.Count AS organismQuantity,
    'pairs' AS organismQuantityType,
    'aggregated count for ' + CONVERT(varchar, dbo.ASkjemaInfo.nPkt)
        + ' sampling points and line sampling situated less than 5000m from location' AS occurrenceRemarks,
    dbo.Art.Artsnavn_Lat AS scientificName,
    dbo.Art.Kingdom,
    dbo.Art.Phylum,
    dbo.Art.Class,
    dbo.Art.[Order],
    dbo.Art.Family,
    dbo.Art.Genus,
    dbo.Art.Species AS specificEpithet,
    dbo.Art.Artsnavn_Norsk AS vernacularName,
    CONVERT(VARCHAR(33), dbo.TrimResults.DatoEndret, 126) AS [dcterms:modified],
    'PRESENT' AS occurrenceStatus
FROM dbo.TrimResults
INNER JOIN dbo.Art ON dbo.TrimResults.Species = dbo.Art.ArtsID
INNER JOIN dbo.ASkjemaInfo ON dbo.TrimResults.Site = dbo.ASkjemaInfo.RUTENR
LEFT OUTER JOIN Metadata.dbo.Kommune AS Komm ON Komm.nr = dbo.ASkjemaInfo.Komid
INNER JOIN dbo.Ruteinformasjon ON dbo.Ruteinformasjon.Aar = dbo.TrimResults.Year
    AND dbo.Ruteinformasjon.FK_RuteID = dbo.TrimResults.Site
WHERE (dbo.TrimResults.Count > 0)
    AND (ISNULL(dbo.Art.SkjulDatadeling, 0) <> 1)
    AND (dbo.Art.ArtsID < 9998);
GO
