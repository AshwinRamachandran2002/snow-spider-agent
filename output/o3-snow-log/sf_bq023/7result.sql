/*---------------------------------------------------------------------------
  Average 2020 individual-donation amount and 2018 ACS median income
  by Census Tract – Kings County (FIPS 36047, Brooklyn), New York
---------------------------------------------------------------------------*/
WITH tract_income AS (     -- 2018 ACS 5-Year, build tract-level median income
    SELECT
        SUBSTR("geo_id",1,11)                    AS "census_tract_geoid",   -- 11-digit tract GEOID
        AVG("median_income")                     AS "median_income"         -- average across block-groups in tract
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE SUBSTR("geo_id",1,5) = '36047'                                    -- Kings County (Brooklyn)
    GROUP BY "census_tract_geoid"
),

donors_ny AS (          -- 2020 FEC individual contributions – New York donors
    SELECT
        SUBSTR("zip_code",1,5)                   AS "zip5",
        "transaction_amt"
    FROM FEC.FEC.INDIVIDUALS_INGEST_2020
    WHERE "state" = 'NY'
      AND "transaction_amt" IS NOT NULL
),

donor_tract AS (        -- map donors to census tracts via HUD ZIP ↔ tract cross-walk
    SELECT
        cw."census_tract_geoid",
        d."transaction_amt"
    FROM donors_ny d
    JOIN FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE cw
          ON cw."zip_code" = d."zip5"
    WHERE cw."census_tract_geoid" LIKE '36047%'                            -- keep only Kings County tracts
),

tract_donations AS (    -- average donation per tract
    SELECT
        "census_tract_geoid",
        AVG("transaction_amt")          AS "avg_donation_amt"
    FROM donor_tract
    GROUP BY "census_tract_geoid"
)

SELECT
    ti."census_tract_geoid",
    ti."median_income",
    td."avg_donation_amt"
FROM tract_income  ti
LEFT JOIN tract_donations td
       ON ti."census_tract_geoid" = td."census_tract_geoid"
ORDER BY ti."census_tract_geoid";