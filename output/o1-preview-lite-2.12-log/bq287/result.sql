WITH utah_zip_codes AS (
  SELECT DISTINCT
    zip_code
  FROM
    `bigquery-public-data.hud_zipcode_crosswalk.zip_to_county`
  WHERE
    SUBSTR(county_geoid, 1, 2) = '49'  -- Utah state FIPS code
    AND zip_code IS NOT NULL
    AND zip_code != ''
),

bank_locations AS (
  SELECT
    LEFT(zip_code, 5) AS zip_code,
    COUNT(*) AS num_locations
  FROM
    `bigquery-public-data.fdic_banks.locations`
  WHERE
    state = 'UT'
    AND zip_code IS NOT NULL
    AND zip_code != ''
  GROUP BY
    zip_code
),

zip_counts AS (
  SELECT
    uz.zip_code,
    COALESCE(bl.num_locations, 0) AS num_locations
  FROM
    utah_zip_codes uz
  LEFT JOIN
    bank_locations bl
  ON
    uz.zip_code = bl.zip_code
),

min_locations AS (
  SELECT
    MIN(num_locations) AS min_num_locations
  FROM
    zip_counts
)

SELECT
  ROUND(ed.employment_rate, 4) AS Employment_rate
FROM
  (
    SELECT
      RIGHT(geo_id, 5) AS zip_code,
      (SAFE_DIVIDE(employed_pop, pop_16_over)) * 100 AS employment_rate
    FROM
      `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr`
    WHERE
      pop_16_over > 0
  ) ed
JOIN
  zip_counts zc
ON
  ed.zip_code = zc.zip_code
WHERE
  zc.num_locations = (SELECT min_num_locations FROM min_locations)
ORDER BY
  ed.zip_code ASC
LIMIT 1;