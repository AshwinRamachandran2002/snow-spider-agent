WITH donors_ny AS (        -- 1. 2020 individual contributions made in New York
    SELECT
        REGEXP_SUBSTR("zip_code", '^[0-9]{5}')      AS zip5,       -- first five ZIP digits
        "transaction_amt"
    FROM FEC.FEC."INDIVIDUALS_INGEST_2020"
    WHERE "state" = 'NY'
      AND "transaction_amt" IS NOT NULL
),
donors_with_tract AS (     -- 2. map those ZIPs to 2010 Census tracts
    SELECT
        ct."census_tract_geoid"                     AS tract_geoid,
        dn."transaction_amt"
    FROM donors_ny                       dn
    JOIN FEC.HUD_ZIPCODE_CROSSWALK."CENSUS_TRACTS_TO_ZIPCODE"  ct
          ON dn.zip5 = ct."zip_code"
    WHERE ct."census_tract_geoid" LIKE '36047%'                 -- Kings Co. (Brooklyn)
),
avg_donation_per_tract AS ( -- 3. average donation per tract
    SELECT
        tract_geoid,
        AVG("transaction_amt")                  AS avg_donation
    FROM donors_with_tract
    GROUP BY tract_geoid
),
median_income_per_tract AS ( -- 4. 2018 ACS median household income, rolled-up from block-groups
    SELECT
        SUBSTR("geo_id",1,11)                   AS tract_geoid,   -- convert BG GEOID → tract GEOID
        AVG("median_income")                    AS median_income_2018
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."BLOCKGROUP_2018_5YR"
    WHERE "geo_id" LIKE '36047%'                                -- Kings Co. (Brooklyn)
      AND "median_income" IS NOT NULL
    GROUP BY tract_geoid
)
-- 5. combine donations and income
SELECT
    d.tract_geoid,
    d.avg_donation,
    m.median_income_2018
FROM avg_donation_per_tract   d
LEFT JOIN median_income_per_tract m
       ON d.tract_geoid = m.tract_geoid
ORDER BY d.tract_geoid;