# Norsk hekkefuglovervåking – Norwegian Bird Monitoring

This repository contains NINA-managed code and analysis workflows used in
the Norwegian Bird Monitoring programme.

The monitoring programme is carried out by the Norwegian Institute for
Nature Research (NINA) and BirdLife Norway on behalf of the Norwegian
Environment Agency.

## Data products

The project data management plan defines four main data products:

| ID | Data product | Delivery and availability |
|---|---|---|
| D1 | Primary monitoring data | Annual quality-assured CSV extracts delivered to the Norwegian Environment Agency, accompanied by metadata and a data dictionary. |
| D2 | Public sampling-event dataset | Published through NINA's IPT and GBIF, with spatial generalisation and species sensitivity restrictions. |
| D3 | Species population indices | Annual species-level indices and associated methodological documentation. |
| D4 | Multi-species indicators | Annual multi-species indicators and associated methodological documentation. |

This repository documents the NINA-managed code, data transformations
and analysis workflows supporting these data products.

Non-public primary data, exact monitoring locations and personal
information are not included in this repository.

## Repository contents

### `sql/prepare-analysis-data.sql`

SQL Server workflow used to prepare quality-assured monitoring data for
population trend analyses and other annual data deliveries.

The script applies project-specific quality criteria and prepares the
route-year-species dataset used as input to subsequent analyses.

Additional R scripts and documentation of the analysis workflow will be
added as the existing workflow is reviewed and documented.

### `sql/ipt/`

SQL Server view definitions used as data sources for the public
Darwin Core sampling-event dataset (D2).

- `vwDwC_Events.sql` – Event Core source view.
- `vwDwC_Occurrence.sql` – Occurrence extension source view.

### `docs/d2-publication.md`

Documentation of the public occurrence dataset (D2), including data 
preparation, Darwin Core mapping, quality criteria, spatial generalisation 
and publication through NINA's IPT and GBIF.

See [D2 publication documentation](docs/d2-publication.md).

## Analysis workflow

The general workflow is:

1. Field observations are entered into the project database.
2. Data are quality-assured by BirdLife Norway and NINA.
3. `prepare-analysis-data.sql` prepares the approved analysis dataset.
4. Species population indices are calculated using PECBMS methodology
   and RTRIM/rtrim-shell.
5. Multi-species indicators are calculated using PECBMS methodology.
6. Results and data products are published through the relevant project
   services.

## Documentation

The database structure and data flow are described in:

Vang, R. et al. 2023. *Norsk hekkefuglovervåking systemdokumentasjon*.
NINA Report 2230.

## Primary monitoring data (D1)

Quality-assured monitoring data are delivered annually to the
Norwegian Environment Agency in accordance with the project
data management plan.

The delivery includes:

- `Koordinater.csv` – monitoring-point coordinates.
- `Punkttaksering.csv` – species counts at point level.
- `Linjetaksering.csv` – species counts from line surveys at route level.
- A Markdown README containing metadata, a data dictionary,
  quality criteria and documentation of count calculations.

Counts are expressed as pair equivalents, including species-specific
conversion of flock observations.

The delivered files represent an agreed extract of the operational
database, rather than a complete export of the original field records.

D1 contains detailed monitoring locations and is not published
in this repository. Annual delivery files and their corresponding
metadata are retained in the controlled project archive.

## Public data publication (D2)

The quality-assured public sampling-event dataset is published through NINA's IPT and registered with GBIF as a Darwin Core Event Core with an Occurrence extension.

- [IPT resource and dataset versions](https://ipt.nina.no/resource?r=tove_birdsampling)
- [GBIF dataset – DOI 10.15468/6jmw2e](https://doi.org/10.15468/6jmw2e)
- [Technical documentation of the D2 publication workflow](docs/d2-publication.md)

IPT is the authoritative source for published data, scientific metadata and dataset version history. This repository documents the NINA-managed data preparation and publication workflow. Exact monitoring locations and other non-public primary data are not included here. The public dataset is licensed under CC BY 4.0; the repository's MIT licence applies to NINA-managed code.


## License

NINA-managed code in this repository is licensed under the MIT License.
See [LICENSE](LICENSE) for details.
