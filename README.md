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

## Licence

See the `LICENSE` file.
