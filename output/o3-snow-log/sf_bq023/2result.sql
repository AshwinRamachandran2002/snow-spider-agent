/* ----------------------------------------------------------------------
   Average 2020 individual political donation vs. 2018 ACS median income
   for every Census Tract in Kings County (Brooklyn), New York
------------------------------------------------------------------------ */
WITH

/* 1.  ZIP-to-tract pairs that sit inside Kings County (state-county FIPS 36047) */
crosswalk_kings AS (
    SELECT
        "census_tract_geoid"                    AS "tract_geoid",   -- 11-digit tract GEOID
        "zip_code"                              AS "zip5"
    FROM FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE
    WHERE LEFT("census_tract_geoid", 5) = '36047'                   -- Kings County
),

/* 2.  2020 individual contributors who live in New York               */
donors_ny AS (
    SELECT
        SUBSTR("zip_code", 1, 5)                AS "zip5",
        "transaction_amt"                       AS "donation_amt"
    FROM FEC.FEC.INDIVIDUALS_INGEST_2020
    WHERE "state" = 'NY'
      AND "transaction_amt" IS NOT NULL
),

/* 3.  2020 average donation per Kings-County tract                    */
donations_by_tract AS (
    SELECT
        cw."tract_geoid",
        AVG(d."donation_amt")                   AS "avg_donation_amt"
    FROM crosswalk_kings  cw
    JOIN donors_ny         d  ON cw."zip5" = d."zip5"
    GROUP BY cw."tract_geoid"
),

/* 4.  2018 5-yr ACS median income aggregated from block-groups 
        to the tract level for Kings County                            */
median_income_tract AS (
    SELECT
        SUBSTR("geo_id", 1, 11)                 AS "tract_geoid",
        AVG("median_income")                    AS "tract_median_income"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE LEFT("geo_id", 5) = '36047'                               -- Kings County
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
)

/* 5.  Final result: tract GEOID, avg donation, ACS median income      */
SELECT
    d."tract_geoid",
    d."avg_donation_amt",
    m."tract_median_income"
FROM donations_by_tract d
LEFT JOIN median_income_tract m
       ON d."tract_geoid" = m."tract_geoid"
ORDER BY d."avg_donation_amt" DESC NULLS LAST;