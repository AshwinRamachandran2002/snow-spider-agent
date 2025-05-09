SELECT
    c."geo_id",
    ROUND(AVG(f."transaction_amt"), 4) AS "avg_donation",
    c."median_income"
FROM
    "FEC"."FEC"."INDIVIDUALS_INGEST_2020" f
JOIN "FEC"."HUD_ZIPCODE_CROSSWALK"."ZIPCODE_TO_CENSUS_TRACTS" z
    ON LEFT(TRIM(f."zip_code"), 5) = z."zip_code"
JOIN "FEC"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" c
    ON c."geo_id" = z."census_tract_geoid"
WHERE
    TRIM(f."state") = 'NY'
    AND f."city" ILIKE '%Brooklyn%'
    AND f."transaction_amt" IS NOT NULL
    AND f."transaction_dt" BETWEEN '2020-01-01' AND '2020-12-31'
    AND z."census_tract_geoid" LIKE '36047%'  -- Census tracts in Kings County
GROUP BY
    c."geo_id", c."median_income"
ORDER BY
    c."geo_id";