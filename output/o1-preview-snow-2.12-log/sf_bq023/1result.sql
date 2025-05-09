WITH kings_tracts AS (
    SELECT DISTINCT "geo_id"
    FROM "FEC"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK"
    WHERE "county_fips_code" = '047'
),
donor_donations AS (
    SELECT
        donors."zip_code",
        donors."transaction_amt"
    FROM "FEC"."FEC"."INDIVIDUALS_INGEST_2020" AS donors
    WHERE donors."state" = 'NY'
),
zip_to_tract AS (
    SELECT
        xwalk."zip_code",
        xwalk."census_tract_geoid",
        xwalk."residential_ratio"
    FROM "FEC"."HUD_ZIPCODE_CROSSWALK"."ZIPCODE_TO_CENSUS_TRACTS" AS xwalk
),
donations_with_tract AS (
    SELECT
        dd."transaction_amt",
        zt."census_tract_geoid",
        zt."residential_ratio"
    FROM donor_donations AS dd
    INNER JOIN zip_to_tract AS zt
        ON dd."zip_code" = zt."zip_code"
),
donations_in_kings AS (
    SELECT
        dt."census_tract_geoid",
        dt."transaction_amt",
        dt."residential_ratio"
    FROM donations_with_tract AS dt
    INNER JOIN kings_tracts AS kt
        ON dt."census_tract_geoid" = kt."geo_id"
),
donations_grouped AS (
    SELECT
        dt."census_tract_geoid",
        SUM(dt."transaction_amt" * dt."residential_ratio") / NULLIF(SUM(dt."residential_ratio"), 0) AS "Average_Donation"
    FROM donations_in_kings AS dt
    GROUP BY dt."census_tract_geoid"
),
median_incomes AS (
    SELECT "geo_id", "median_income"
    FROM "FEC"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR"
    WHERE "geo_id" IN (
        SELECT "geo_id" FROM kings_tracts
    )
)
SELECT
    dg."census_tract_geoid" AS "Census_Tract_GeoID",
    ROUND(dg."Average_Donation", 4) AS "Average_Donation",
    mi."median_income" AS "Median_Income"
FROM donations_grouped AS dg
LEFT JOIN median_incomes AS mi
    ON dg."census_tract_geoid" = mi."geo_id"
ORDER BY "Census_Tract_GeoID";