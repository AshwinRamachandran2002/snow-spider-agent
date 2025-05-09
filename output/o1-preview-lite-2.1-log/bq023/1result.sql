WITH tract_donations AS (
  SELECT
    h.census_tract_geoid AS census_tract_id,
    i.transaction_amt * h.residential_ratio AS weighted_donation,
    h.residential_ratio
  FROM
    `bigquery-public-data.fec.individuals_ingest_2020` AS i
  JOIN
    `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS h
    ON SUBSTR(i.zip_code, 1, 5) = h.zip_code
  WHERE
    i.state = 'NY'
    AND LOWER(i.city) LIKE '%brooklyn%'
    AND i.transaction_amt > 0
    AND h.residential_ratio > 0
),
donations_by_tract AS (
  SELECT
    census_tract_id,
    SUM(weighted_donation) AS total_weighted_donation,
    SUM(residential_ratio) AS total_residential_ratio
  FROM
    tract_donations
  GROUP BY
    census_tract_id
),
average_donations AS (
  SELECT
    census_tract_id,
    ROUND(total_weighted_donation / total_residential_ratio, 4) AS average_political_donation_amount
  FROM
    donations_by_tract
),
kings_county_tracts AS (
  SELECT
    geo_id
  FROM
    `bigquery-public-data.geo_census_tracts.census_tracts_new_york`
  WHERE
    county_fips_code = '047'
),
tract_incomes AS (
  SELECT
    geo_id AS census_tract_id,
    median_income
  FROM
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE
    geo_id IN (SELECT geo_id FROM kings_county_tracts)
)
SELECT
  a.census_tract_id,
  a.average_political_donation_amount,
  t.median_income
FROM
  average_donations AS a
JOIN
  tract_incomes AS t
  ON a.census_tract_id = t.census_tract_id
ORDER BY
  a.census_tract_id;