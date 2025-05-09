WITH bank_counts AS (
  SELECT
    LEFT(zip_code, 5) AS zip_code,
    COUNT(*) AS bank_locations_count
  FROM
    `bigquery-public-data.fdic_banks.locations`
  WHERE
    state = 'UT'
    AND zip_code IS NOT NULL
  GROUP BY
    LEFT(zip_code, 5)
),
min_banks AS (
  SELECT
    MIN(bank_locations_count) AS min_bank_locations
  FROM
    bank_counts
),
zips_with_min_banks AS (
  SELECT
    zip_code
  FROM
    bank_counts
  WHERE
    bank_locations_count = (SELECT min_bank_locations FROM min_banks)
  LIMIT 1
),
census_data AS (
  SELECT
    SUBSTR(geo_id, LENGTH(geo_id) - 4, 5) AS zip_code,
    employed_pop,
    pop_16_over
  FROM
    `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  WHERE
    pop_16_over > 0
),
joined_data AS (
  SELECT
    zwb.zip_code,
    cd.employed_pop,
    cd.pop_16_over,
    SAFE_MULTIPLY(SAFE_DIVIDE(cd.employed_pop, cd.pop_16_over), 100) AS employment_rate
  FROM
    zips_with_min_banks zwb
  JOIN
    census_data cd
  ON
    zwb.zip_code = cd.zip_code
)
SELECT
  zip_code,
  ROUND(employment_rate, 4) AS employment_rate
FROM
  joined_data;