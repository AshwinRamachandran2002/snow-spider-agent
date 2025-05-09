/*  Kings County (Brooklyn, NY) – 2020 individual-donor average contribution
    matched to 2018 ACS 5-Year median household income at the Census-tract level  */

WITH tract_income AS (          /* 2018 ACS median income – aggregate block-groups to tracts */
    SELECT
        SUBSTR("geo_id",1,11)                 AS "census_tract_geoid",   -- 11-digit tract GEOID
        AVG("median_income")                  AS "median_income"
    FROM   CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE  "geo_id" LIKE '36047%'                                -- Kings County (state 36, county 047)
    GROUP  BY SUBSTR("geo_id",1,11)
),

donations AS (                  /* 2020 FEC individual contributions – NY donors, clean ZIP */
    SELECT
        LEFT(TRIM("zip_code"),5)              AS "zip5",          -- first 5 digits of ZIP
        CAST("transaction_amt" AS FLOAT)      AS "transaction_amt"
    FROM   FEC.FEC.INDIVIDUALS_INGEST_2020
    WHERE  "state" = 'NY'
      AND  "zip_code"      IS NOT NULL
      AND  "transaction_amt" IS NOT NULL
),

donations_tract AS (            /* map ZIPs to Census tracts via HUD cross-walk */
    SELECT
        x."census_tract_geoid",
        d."transaction_amt"
    FROM   donations d
    JOIN   FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE x
           ON x."zip_code" = d."zip5"
    WHERE  x."census_tract_geoid" LIKE '36047%'                    -- limit to Kings County tracts
),

tract_don_stats AS (            /* average donation per tract */
    SELECT
        "census_tract_geoid",
        AVG("transaction_amt")  AS "avg_donation_amt"
    FROM   donations_tract
    GROUP  BY "census_tract_geoid"
)

/* final list: every Kings County tract with income, plus avg donation (NULL if none) */
SELECT
    ti."census_tract_geoid",
    td."avg_donation_amt",
    ti."median_income"
FROM   tract_income ti
LEFT   JOIN tract_don_stats td
       ON ti."census_tract_geoid" = td."census_tract_geoid"
ORDER  BY ti."census_tract_geoid";