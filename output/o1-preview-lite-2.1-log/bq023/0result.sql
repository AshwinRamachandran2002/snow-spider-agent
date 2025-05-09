SELECT
  ct.geo_id AS census_tract_id,
  ROUND(SUM(i.transaction_amt * zc.total_ratio) / SUM(zc.total_ratio), 4) AS average_political_donation_amount,
  ct.median_income
FROM
  `bigquery-public-data.fec.individuals_ingest_2020` AS i
JOIN
  `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS zc
  ON i.zip_code = zc.zip_code
JOIN
  `bigquery-public-data.geo_census_tracts.census_tracts_new_york` AS gct
  ON zc.census_tract_geoid = gct.geo_id
JOIN
  `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS ct
  ON zc.census_tract_geoid = ct.geo_id
WHERE
  gct.county_fips_code = '047'  -- Kings County (Brooklyn)
GROUP BY
  ct.geo_id,
  ct.median_income
ORDER BY
  ct.geo_id;