/*--------------------------------------------------------------------
  Kings County (Brooklyn, NY) – 2018 ACS median household income
  & 2020 FEC individual-contribution averages by Census Tract
--------------------------------------------------------------------*/
WITH donors_ny AS (           /* 1. NY-state donors, keep 5-digit ZIP */
    SELECT 
        SUBSTR("zip_code",1,5)        AS "zip5",
        CAST("transaction_amt" AS FLOAT) AS "transaction_amt"
    FROM FEC.FEC."INDIVIDUALS_INGEST_2020"
    WHERE UPPER("state") = 'NY'
      AND "transaction_amt" IS NOT NULL
      AND REGEXP_LIKE(SUBSTR("zip_code",1,5),'^[0-9]{5}$')
), donors_tract AS (          /* 2. Map ZIP → Census-tract, keep Kings Cty */
    SELECT 
        x."census_tract_geoid"       AS "tract_geoid",
        d."transaction_amt"
    FROM donors_ny                 d
    JOIN FEC.HUD_ZIPCODE_CROSSWALK."CENSUS_TRACTS_TO_ZIPCODE" x
          ON x."zip_code" = d."zip5"
    WHERE SUBSTR(x."census_tract_geoid",1,5) = '36047'      -- Kings County
), avg_don_by_tract AS (      /* 3. Avg donation per tract */
    SELECT
        "tract_geoid",
        AVG("transaction_amt")      AS "avg_donation"
    FROM donors_tract
    GROUP BY "tract_geoid"
), tract_income AS (          /* 4. 2018 ACS – median income per tract  */
    SELECT
        SUBSTR("geo_id",1,11)       AS "tract_geoid",
        MEDIAN("median_income")     AS "tract_median_income"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."BLOCKGROUP_2018_5YR"
    WHERE SUBSTR("geo_id",1,5) = '36047'                     -- Kings County
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id",1,11)
)
/*--------------------------------------------------------------------
  5. Combine income & donation metrics
--------------------------------------------------------------------*/
SELECT
    i."tract_geoid",
    i."tract_median_income",
    d."avg_donation"
FROM tract_income          i
LEFT JOIN avg_don_by_tract d
       ON d."tract_geoid" = i."tract_geoid"
ORDER BY i."tract_geoid";