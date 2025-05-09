SELECT 
    acs."geo_id" AS "geo_id",
    ROUND(AVG(d."transaction_amt"), 4) AS "avg_donation",
    acs."median_income"
FROM FEC.FEC."INDIVIDUALS_INGEST_2020" AS d
JOIN FEC.HUD_ZIPCODE_CROSSWALK."ZIPCODE_TO_CENSUS_TRACTS" AS cw
    ON TRIM(SUBSTR(d."zip_code", 1, 5)) = LPAD(TRIM(cw."zip_code"), 5, '0')
JOIN FEC.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" AS acs
    ON LPAD(TRIM(cw."census_tract_geoid"), 11, '0') = REPLACE(acs."geo_id", '1400000US', '')
WHERE d."state" = 'NY' 
  AND UPPER(TRIM(d."city")) LIKE '%BROOKLYN%'
  AND cw."census_tract_geoid" LIKE '36047%'  -- Kings County FIPS code
GROUP BY acs."geo_id", acs."median_income"
ORDER BY acs."geo_id";