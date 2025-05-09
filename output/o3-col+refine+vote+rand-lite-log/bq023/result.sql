-- Kings County (Brooklyn, FIPS 36047):
--  • Median household income: ACS 2018–5-year census-tract file
--  • Average 2020 individual FEC donation: indiv20 → ZIP-to-tract HUD cross-walk
WITH tract_donations AS (
  SELECT
    x.census_tract_geoid AS geo_id,
    AVG(d.transaction_amt)         AS avg_donation
  FROM `bigquery-public-data.fec.indiv20`                                      AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts`   AS x
    ON SUBSTR(d.zip_code, 1, 5) = x.zip_code          -- match 5-digit ZIP
  WHERE d.state = 'NY'                                -- New York donors only
    AND d.transaction_amt IS NOT NULL                 -- keep valid amounts
    AND SUBSTR(x.census_tract_geoid, 1, 5) = '36047'  -- Kings County tracts
  GROUP BY x.census_tract_geoid
)

SELECT
  c.geo_id,
  c.median_income,
  t.avg_donation
FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS c
LEFT JOIN tract_donations AS t
  ON c.geo_id = t.geo_id
WHERE SUBSTR(c.geo_id, 1, 5) = '36047'                -- Kings County tracts
ORDER BY c.geo_id;