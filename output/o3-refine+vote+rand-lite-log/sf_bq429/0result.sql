WITH income_diff AS (     /* ZIP‑level median‑income change, 2015→2018 */
    SELECT
        b."state_fips_code",
        b."state_code",
        b."zip_code",
        ( z18."median_income" - z15."median_income") AS income_diff
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
          ON z15."geo_id" = z18."geo_id"                 -- 5‑digit ZIP GEO_ID
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" b
          ON b."zip_code" = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
),
vulnerable AS (           /* 2017 weighted vulnerable employment per ZIP */
    SELECT
        z17."geo_id" AS "zip_code",
        0.38423645320197042 * COALESCE(z17."employed_wholesale_trade",0) +
        0.48071410777129553 * ( COALESCE(z17."employed_construction",0) +
                                COALESCE(z17."employed_agriculture_forestry_fishing_hunting_mining",0) ) +
        0.89455676291236841 * COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0) +
        0.31315240083507306 * COALESCE(z17."employed_information",0) +
        0.51000000000000000 * COALESCE(z17."employed_retail_trade",0)     AS vulnerable_emp
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z17
),
state_zip AS (           /* merge the two datasets */
    SELECT
        i."state_fips_code",
        i."state_code",
        i."zip_code",
        i.income_diff,
        v.vulnerable_emp
    FROM income_diff i
    LEFT JOIN vulnerable v
           ON i."zip_code" = v."zip_code"
),
state_avgs AS (          /* compute average per state */
    SELECT
        "state_fips_code",
        MAX("state_code") AS state_code,
        AVG(income_diff)  AS avg_income_diff,
        AVG(vulnerable_emp) AS avg_vulnerable_emp
    FROM state_zip
    GROUP BY "state_fips_code"
)
SELECT
    sf."postal_code"                         AS state,
    ROUND(sa.avg_income_diff   , 2)          AS average_median_income_difference_2018_2015,
    ROUND(sa.avg_vulnerable_emp, 2)          AS average_vulnerable_employees_2017
FROM state_avgs sa
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" sf
      ON sf."postal_code" = sa.state_code
ORDER BY sa.avg_income_diff DESC NULLS LAST,
         state
LIMIT 5;