SELECT
  acs.geo_id AS census_tract,
  acs.median_income,
  ROUND(
    SUM(f.transaction_amt * CAST(x.total_ratio AS FLOAT64)) /
    SUM(CAST(x.total_ratio AS FLOAT64)), 
    4
  ) AS avg_donation
FROM `bigquery-public-data.fec.individuals_ingest_2020` AS f
JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS x
  ON x.zip_code = LPAD(SUBSTR(CAST(f.zip_code AS STRING), 1, 5), 5, '0')
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS acs
  ON acs.geo_id = x.census_tract_geoid
WHERE f.state = 'NY'
  AND f.transaction_amt IS NOT NULL
  AND acs.geo_id LIKE '36047%'        -- Kings County (Brooklyn)
GROUP BY
  census_tract,
  acs.median_income
ORDER BY
  census_tract;