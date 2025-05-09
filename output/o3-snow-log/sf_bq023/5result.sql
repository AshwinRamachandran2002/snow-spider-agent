/* ------------------------------------------------------------------
   Kings County (Brooklyn, NY) – 2018 ACS median income (tract level)
   vs. 2020 FEC individual-contribution averages (tract level)
-------------------------------------------------------------------*/
WITH

/* 1.  2018 ACS – aggregate block-group income up to census-tract */
tract_income AS (
    SELECT
        SUBSTR("geo_id",1,11)                    AS tract_geoid,   -- 11-digit tract GEOID
        AVG("median_income")                     AS tract_median_income
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE  "median_income" IS NOT NULL
      AND  SUBSTR("geo_id",1,2)  = '36'          -- State = NY
      AND  SUBSTR("geo_id",3,3)  = '047'         -- County = Kings (Brooklyn)
    GROUP BY SUBSTR("geo_id",1,11)
),

/* 2.  2020 FEC individual contributions – NY donors, 5-digit ZIP */
donors_ny AS (
    SELECT
        LPAD(SUBSTR("zip_code",1,5),5,'0')       AS zip5,
        "transaction_amt"                        AS donation_amt
    FROM FEC.FEC.INDIVIDUALS_INGEST_2020
    WHERE "state" = 'NY'
      AND "transaction_amt" IS NOT NULL
      AND "zip_code" IS NOT NULL
),

/* 3.  Map ZIPs → census tracts via HUD cross-walk */
donors_with_tract AS (
    SELECT
        ctz."census_tract_geoid"                 AS tract_geoid,
        d.donation_amt
    FROM donors_ny                 d
    JOIN FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE  ctz
          ON ctz."zip_code" = d.zip5
    WHERE SUBSTR(ctz."census_tract_geoid",1,2) = '36'        -- NY
      AND SUBSTR(ctz."census_tract_geoid",3,3) = '047'       -- Kings
),

/* 4.  Average donation amount per tract */
tract_donation_avg AS (
    SELECT
        tract_geoid,
        AVG(donation_amt)                        AS avg_donation_amt
    FROM donors_with_tract
    GROUP BY tract_geoid
)

/* 5.  Final list: every Kings-County tract with income & donation */
SELECT
    ti.tract_geoid,
    tda.avg_donation_amt,
    ti.tract_median_income
FROM tract_income          ti
LEFT JOIN tract_donation_avg tda
       ON ti.tract_geoid = tda.tract_geoid
ORDER BY ti.tract_geoid;