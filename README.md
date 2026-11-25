# Norsk hekkefuglovervåking – Norwegian Bird Monitoring

This repository contains NINA-managed code and analysis workflows used in
the Norwegian Bird Monitoring programme.

The monitoring programme is carried out by the Norwegian Institute for
Nature Research (NINA) and BirdLife Norway on behalf of the Norwegian
Environment Agency.

## Repository contents

### `sql/prepare-analysis-data.sql`

SQL Server workflow used to prepare quality-assured monitoring data for
population trend analyses and other annual data deliveries.

The script applies project-specific quality criteria and prepares the
route-year-species dataset used as input to subsequent analyses.

Additional R scripts and documentation of the analysis workflow will be
added as the existing workflow is reviewed and documented.

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

## Public data publication (D2)

The quality-assured public sampling-event dataset is published through NINA's IPT and registered with GBIF as a Darwin Core Event Core with an Occurrence extension.

- [IPT resource and dataset versions](https://ipt.nina.no/resource?r=tove_birdsampling)
- [GBIF dataset – DOI 10.15468/6jmw2e](https://doi.org/10.15468/6jmw2e)
- [Technical documentation of the D2 publication workflow](docs/d2-publication.md)

IPT is the authoritative source for published data, scientific metadata and dataset version history. This repository documents the NINA-managed data preparation and publication workflow. Exact monitoring locations and other non-public primary data are not included here. The public dataset is licensed under CC BY 4.0; the repository's MIT licence applies to NINA-managed code.


## License

NINA-managed code in this repository is licensed under the MIT License.
See [LICENSE](LICENSE) for details.
