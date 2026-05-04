# intervalwise-test-data

ComStock TMY3 timeseries data and TMY3 weather data for Intervalwise demo institution generation.

## Contents

```
comstock_raw/
  primary_school_zone4c.csv      # 35,040 rows, 15-min intervals, 1 TMY year
  secondary_school_zone4c.csv
  medium_office_zone4c.csv
  small_office_zone4c.csv
weather/
  the_dalles_or_tmy3.csv         # Daily high °F, The Dalles OR (CGCC main campus)
  hood_river_or_tmy3.csv         # Daily high °F, Hood River OR (satellite campus)
building_mappings.yml            # Maps each demo building to a ComStock source file + scaling factors
scripts/
  download_from_oedi.sh          # Re-fetch source files from NREL OEDI S3 if needed
```

## Data Source and Attribution

ComStock timeseries data sourced from the **NREL End-Use Load Profiles (EULP) for the U.S. Building Stock** dataset:

> Lucas, Robert, Colin Sheppard, Chris CaraDonna, Alex Swindler, Raymond Atiles, Natalie Mims Frick, and Elaina Present. 2022. *End-Use Load Profiles for the U.S. Building Stock*. Golden, CO: National Renewable Energy Laboratory. NREL/TP-5500-80889. https://www.nrel.gov/docs/fy22osti/80889.pdf

- Dataset hosted at: https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/
- ComStock subset: `comstock_tmy3_release_1`
- Climate zone: ASHRAE/IECC 4C (Marine Cool — Pacific Northwest)
- Temporal resolution: 15-minute intervals, one TMY (Typical Meteorological Year) year
- Columns used: `electricity_facility_kwh` (aggregate total electricity, all end uses)

The `floor_area_represented` field from each aggregate file is stored as `comstock_sqft` in `building_mappings.yml`. Intervalwise scales raw aggregate kWh to demo building size:

```
scaled_kwh = raw_aggregate_kwh * (demo_sqft / floor_area_represented)
```

Weather data sourced from TMY3 county-level files in the same OEDI dataset, transformed from hourly °C dry-bulb to daily maximum °F.

**License**: ComStock data is published by DOE/NREL under a permissive open data license permitting redistribution with attribution. See https://data.openei.org/ for full terms.

## Synthetic Adjustments

The raw ComStock timeseries is used as a base profile. Intervalwise's `DemoData::Generator` applies the following synthetic adjustments at generation time (not stored here):

1. **Morning HVAC startup spike** — 15–25% load increase across 3–4 buildings on cool Mondays (Oct–Mar), 7:30–8:00 AM
2. **Summer afternoon peak** — 10–15% load increase in cooling-dominated buildings on hot weekday afternoons (Jun–Sep, T > 88°F), 2–4 PM
3. **Vocational program peaks** — Equipment spikes in Regional Skills Center and Electro-Mechanical Tech on weekday afternoons during academic year, 1–3 PM
4. **Anomaly injection** — 2–3 weekend baseload elevations, 1–2 unexpected weekday spikes, 1 low-consumption maintenance closure per building per year
5. **Quality flag variation** — 95% actual, 4% estimated, 1% missing (realistic utility data gaps)

These adjustments are code-only in `app/services/demo_data/adjustment/`. The raw data in this repository is unmodified from the NREL source.

## Demo Institution

This data populates **Columbia Gorge Community College (Demo)** (`cgcc-demo` subdomain) in Intervalwise. This is entirely simulated data — it does not reflect actual energy consumption by Columbia Gorge Community College or any real customer.

Buildings mapped:

| Building | ComStock Type | Demo sqft |
|----------|--------------|-----------|
| Center Building | primary_school_zone4c | 130,000 |
| Administrative | medium_office_zone4c | 45,000 |
| Science Hall | secondary_school_zone4c | 65,000 |
| Health Sciences | primary_school_zone4c | 38,000 |
| Regional Skills Center | secondary_school_zone4c | 52,000 |
| Electro-Mechanical Tech | secondary_school_zone4c | 41,000 |
| Hood River Indian Creek Campus | small_office_zone4c | 28,000 |
| Student Housing | small_office_zone4c | 35,000 |

## Regenerating from Source

If the ComStock files need to be re-fetched from NREL OEDI:

```bash
./scripts/download_from_oedi.sh
```

Requires AWS CLI with public S3 access (no credentials needed for OEDI public bucket):

```bash
aws configure set default.s3.signature_version s3
```

## Usage

```bash
rake demo:full_setup
```

Or step by step:

```bash
rake demo:download          # Clone/pull this repo to /tmp/intervalwise-test-data
rake demo:create_institution # Create CGCC demo institution, campuses, buildings, meters
rake demo:generate           # Generate 13 months of consumption readings + artifacts
```

Set `DEMO_DATA_PATH` to override the default `/tmp/intervalwise-test-data` path:

```bash
DEMO_DATA_PATH=/path/to/intervalwise-test-data rake demo:generate
```
