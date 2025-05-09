SELECT
  acs.`geo_id` AS census_tract,
  acs.`median_income`,
  ROUND(
    SUM(f.`transaction_amt` * CAST(cw.`total_ratio` AS FLOAT64)) /
    SUM(CAST(cw.`total_ratio` AS FLOAT64)),
    4
  ) AS avg_donation
FROM `bigquery-public-data.fec.individuals_ingest_2020` AS f
JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS cw
  ON LPAD(SUBSTR(CAST(f.`zip_code` AS STRING), 1, 5), 5, '0') = cw.`zip_code`
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS acs
  ON cw.`census_tract_geoid` = acs.`geo_id`
WHERE f.`state` = 'NY'
  AND LEFT(acs.`geo_id`, 5) = '36047'               -- Kings County (Brooklyn) FIPS
  AND f.`transaction_amt` IS NOT NULL
  AND NOT IS_NAN(f.`transaction_amt`)
GROUP BY census_tract, acs.`median_income`
ORDER BY census_tract;