-- Kings County (Brooklyn) census-tract median income (ACS 2018 5-yr)
-- paired with average 2020 individual-donation amount (FEC),
-- matched via HUD ZIP→census-tract cross-walk
WITH donations_per_tract AS (
  SELECT
    cw.census_tract_geoid                     AS tract_geoid,
    AVG(i.transaction_amt)                    AS avg_donation_amt
  FROM `bigquery-public-data.fec.indiv20`                                   AS i
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS cw
    ON cw.zip_code = SUBSTR(i.zip_code,1,5)      -- 5-digit ZIP
  WHERE i.state = 'NY'                            -- New York donors
    AND i.transaction_amt IS NOT NULL            -- ignore blanks
  GROUP BY tract_geoid
)

SELECT
  a.geo_id              AS census_tract_geoid,
  d.avg_donation_amt,                           -- may be NULL if no donors
  a.median_income
FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS a
LEFT JOIN donations_per_tract AS d
  ON d.tract_geoid = a.geo_id
WHERE STARTS_WITH(a.geo_id,'36047')              -- 36 = NY, 047 = Kings County
ORDER BY census_tract_geoid;