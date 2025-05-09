WITH kings_county_tracts AS (
  SELECT DISTINCT geo_id AS census_tract_geoid
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_new_york`
  WHERE county_fips_code = '047'
),
median_income_by_tract AS (
  SELECT
    a.geo_id AS census_tract_geoid,
    a.median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS a
  WHERE a.geo_id IN (SELECT census_tract_geoid FROM kings_county_tracts)
),
donations_ny AS (
  SELECT 
    SUBSTR(i.zip_code, 1, 5) AS zip_code, 
    i.transaction_amt
  FROM `bigquery-public-data.fec.individuals_ingest_2020` AS i
  WHERE LOWER(i.state) = 'ny' 
    AND i.transaction_amt > 0
    AND i.zip_code IS NOT NULL 
    AND LENGTH(i.zip_code) >= 5
),
donations_with_tracts AS (
  SELECT
    c.census_tract_geoid,
    d.transaction_amt * c.residential_ratio AS allocated_amount
  FROM donations_ny AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS c
    ON d.zip_code = c.zip_code
  WHERE c.census_tract_geoid IN (SELECT census_tract_geoid FROM kings_county_tracts)
)
SELECT
  m.census_tract_geoid,
  m.median_income,
  ROUND(AVG(dw.allocated_amount), 4) AS average_donation_amount
FROM median_income_by_tract AS m
LEFT JOIN donations_with_tracts AS dw
  ON m.census_tract_geoid = dw.census_tract_geoid
GROUP BY m.census_tract_geoid, m.median_income
ORDER BY m.census_tract_geoid;