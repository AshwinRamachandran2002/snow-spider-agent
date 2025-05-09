/*  Average 2020 individual political donation (FEC) 
    and 2018 ACS 5-yr median household income
    for every census tract in Kings County (Brooklyn), NY  */

WITH tract_income AS (   -- 2018 ACS median income aggregated from block–groups to tracts
    SELECT
        SUBSTR("geo_id",1,11)                      AS "tract_geoid",   -- 11-digit tract GEOID
        AVG("median_income")                       AS "median_income"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '36047%'                   -- 36 = NY, 047 = Kings County
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id",1,11)
),

ny_donors AS (        -- 2020 individual contributions made within New York State
    SELECT
        SUBSTR("zip_code",1,5)      AS "zip5",
        "transaction_amt"
    FROM FEC.FEC.INDIVIDUALS_INGEST_2020
    WHERE "state" = 'NY'
      AND "transaction_amt" IS NOT NULL
),

donor_tract AS (      -- map donors to census tracts through HUD ZIP-to-tract cross-walk
    SELECT
        xwalk."census_tract_geoid"  AS "tract_geoid",
        d."transaction_amt"
    FROM ny_donors d
    JOIN FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE xwalk
          ON d."zip5" = xwalk."zip_code"
    WHERE xwalk."census_tract_geoid" LIKE '36047%'   -- Kings County tracts only
),

tract_donation AS (   -- average contribution per tract
    SELECT
        "tract_geoid",
        AVG("transaction_amt")      AS "avg_donation"
    FROM donor_tract
    GROUP BY "tract_geoid"
)

SELECT
    ti."tract_geoid",
    td."avg_donation",
    ti."median_income"
FROM tract_income  ti
LEFT JOIN tract_donation td
       ON ti."tract_geoid" = td."tract_geoid"
ORDER BY ti."tract_geoid";