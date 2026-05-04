#!/usr/bin/env bash
# Re-fetch ComStock TMY3 zone 4C timeseries from NREL OEDI S3.
# Requires AWS CLI. No credentials needed (public bucket).
set -euo pipefail

BUCKET="s3://oedi-data-lake/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock"
RELEASE="comstock_tmy3_release_1"
ZONE="4C"
OUT="$(dirname "$0")/.."

echo "Fetching ComStock zone ${ZONE} timeseries aggregates..."

for TYPE in primary_school secondary_school medium_office small_office; do
  DEST="${OUT}/comstock_raw/${TYPE}_zone4c.csv"
  echo "  -> ${TYPE}..."
  aws s3 cp \
    "${BUCKET}/${RELEASE}/timeseries_aggregates/by_ashrae_iecc_climate_zone_2004/${TYPE}/upgrade=0/state=OR/G41_${ZONE}_${TYPE}_tmy3.csv" \
    "${DEST}" \
    --no-sign-request 2>/dev/null || \
  aws s3 cp \
    "${BUCKET}/${RELEASE}/timeseries_aggregates/by_ashrae_iecc_climate_zone_2004/${TYPE}/upgrade=0/climate_zone=${ZONE}/${TYPE}_${ZONE}_tmy3_agg.csv" \
    "${DEST}" \
    --no-sign-request
  echo "     saved to ${DEST}"
done

echo "Fetching TMY3 weather files..."
for FIPS in G4100650 G4100270; do
  aws s3 cp \
    "${BUCKET}/${RELEASE}/weather/tmy3/${FIPS}_tmy3.csv" \
    "${OUT}/weather/${FIPS}_tmy3_raw.csv" \
    --no-sign-request || echo "  WARNING: ${FIPS} not found — manual download may be needed"
done

echo "Done. See building_mappings.yml for which files map to which demo buildings."
