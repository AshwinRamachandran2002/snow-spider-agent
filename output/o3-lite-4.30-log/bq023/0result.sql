WITH ny_donations AS (
  -- Extract 5‑digit ZIP (left‑padded) and amount for 2020 NY individual contributions
  SELECT
    LPAD(SUBSTR(CAST(zip_code AS STRING), 1, 5), 5, '0') AS zip5,
    transaction_amt
  FROM `bigquery-public-data.fec.individuals_ingest_2020`
  WHERE state = 'NY'
    AND zip_code IS NOT NULL
    AND LENGTH(CAST(zip_code AS STRING)) >= 5
    AND transaction_amt IS NOT NULL
),
zip_to_tract AS (
  -- Map ZIPs to census tracts; keep Kings County (GEOID prefix 36047)
  SELECT
    z.census_tract_geoid                 AS census_tract,
    CAST(z.residential_ratio AS FLOAT64) AS residential_ratio,
    d.transaction_amt
  FROM ny_donations AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS z
    ON z.zip_code = d.zip5
  WHERE z.census_tract_geoid LIKE '36047%'
    AND z.residential_ratio IS NOT NULL
    AND CAST(z.residential_ratio AS FLOAT64) > 0
),
avg_donation_per_tract AS (
  -- Residential‑ratio‑weighted average donation per tract
  SELECT
    census_tract,
    SUM(transaction_amt * residential_ratio) / SUM(residential_ratio) AS avg_donation
  FROM zip_to_tract
  GROUP BY census_tract
),
acs_income AS (
  -- Median household income from 2018 5‑year ACS (do_date = 2014‑01‑01)
  SELECT
    geo_id AS census_tract,
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE geo_id LIKE '36047%'
    AND do_date = '2014-01-01'
)
SELECT
  t.census_tract,
  i.median_income,
  ROUND(t.avg_donation, 4) AS avg_donation
FROM avg_donation_per_tract AS t
JOIN acs_income           AS i
  ON i.census_tract = t.census_tract
ORDER BY t.census_tract;