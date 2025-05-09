SELECT
    cta."geo_id" AS "Census_Tract_GeoID",
    ROUND(AVG(ind."transaction_amt"), 4) AS "Average_Donation",
    cta."median_income" AS "Median_Income"
FROM
    "FEC"."FEC"."INDIVIDUALS_INGEST_2020" AS ind
INNER JOIN
    "FEC"."HUD_ZIPCODE_CROSSWALK"."ZIPCODE_TO_CENSUS_TRACTS" AS ztc
    ON LEFT(ind."zip_code", 5) = ztc."zip_code"
INNER JOIN
    "FEC"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK" AS ctny
    ON ztc."census_tract_geoid" = ctny."geo_id"
    AND ctny."county_fips_code" = '047'
INNER JOIN
    "FEC"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" AS cta
    ON ctny."geo_id" = cta."geo_id"
WHERE
    ind."state" = 'NY'
GROUP BY
    cta."geo_id",
    cta."median_income"
ORDER BY
    cta."geo_id"
;