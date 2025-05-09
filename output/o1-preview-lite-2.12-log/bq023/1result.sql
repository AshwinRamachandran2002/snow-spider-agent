WITH donations AS (
  SELECT 
    f.zip_code, 
    f.transaction_amt, 
    c.census_tract_geoid, 
    c.residential_ratio
  FROM `bigquery-public-data.fec.individuals_ingest_2020` AS f
  INNER JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS c
    ON f.zip_code = c.zip_code
  WHERE f.state = 'NY'
),
adjusted_donations AS (
  SELECT 
    census_tract_geoid,
    transaction_amt * residential_ratio AS adjusted_amt
  FROM donations
),
donations_per_tract AS (
  SELECT 
    census_tract_geoid,
    AVG(adjusted_amt) AS average_donation_amount
  FROM adjusted_donations
  GROUP BY census_tract_geoid
),
tracts_in_kings AS (
  SELECT 
    geo_id
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_new_york`
  WHERE county_fips_code = '047'
),
income_per_tract AS (
  SELECT 
    geo_id, 
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
)
SELECT 
  t.geo_id AS census_tract_geoid,
  i.median_income,
  ROUND(d.average_donation_amount, 4) AS average_donation_amount
FROM tracts_in_kings AS t
LEFT JOIN income_per_tract AS i
  ON t.geo_id = i.geo_id
LEFT JOIN donations_per_tract AS d
  ON t.geo_id = d.census_tract_geoid
ORDER BY census_tract_geoid;