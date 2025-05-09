-- Average 2020 individual-donation amount and 2018 ACS median household income
-- for every census tract in Kings County (Brooklyn), New York
WITH kings_income AS (
  -- 2018 5-Year ACS median income for Kings County census tracts
  SELECT
    geo_id AS tract_geoid,
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE SUBSTR(geo_id, 1, 5) = '36047'        -- Kings County (FIPS 36047)
),
ny20_donations AS (
  -- 2020 individual contributions from New York donors, keep 5-digit ZIP
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip5,
    transaction_amt
  FROM `bigquery-public-data.fec.indiv20`
  WHERE state = 'NY'
    AND zip_code IS NOT NULL
    AND transaction_amt IS NOT NULL
),
donation_by_tract AS (
  -- Map donations to census tracts via HUD ZIP-to-tract cross-walk and
  -- aggregate the average amount per tract (Kings County only)
  SELECT
    cw.census_tract_geoid AS tract_geoid,
    AVG(d.transaction_amt) AS avg_donation_amt
  FROM ny20_donations AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS cw
    ON cw.zip_code = d.zip5
  WHERE SUBSTR(cw.census_tract_geoid, 1, 5) = '36047'   -- Kings County filter
  GROUP BY tract_geoid
)
SELECT
  i.tract_geoid,
  i.median_income,
  t.avg_donation_amt
FROM kings_income AS i
LEFT JOIN donation_by_tract AS t
  ON i.tract_geoid = t.tract_geoid
ORDER BY i.tract_geoid;