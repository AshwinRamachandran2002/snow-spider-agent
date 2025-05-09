/*  Vulnerable workers by state  (Wholesale‑trade 38%  +  Manufacturing 41%)  */

WITH income_diff AS (          -- 1. ZIP‑level median–income change 2015 → 2018
    SELECT
        e18."geo_id"                                           AS "zip",
        COALESCE(e18."median_income",0)
          - COALESCE(e15."median_income",0)                    AS "income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  e18
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  e15
          ON e18."geo_id" = e15."geo_id"
),
employment_17 AS (            -- 2. 2017 ZIP‑level employment
    SELECT
        "geo_id"                                AS "zip",
        COALESCE("employed_wholesale_trade",0)  AS "wholesale_emp",
        COALESCE("employed_manufacturing",0)    AS "manufact_emp"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),
zip_state AS (                -- 3. ZIP → two‑letter state
    SELECT
        "zip_code"  AS "zip",
        "state_code"
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"
),
zip_vulnerable AS (           -- 4. vulnerable counts per ZIP
    SELECT
        s."state_code",
        0.38 * e."wholesale_emp" AS "vul_wholesale",
        0.41 * e."manufact_emp"  AS "vul_manufact"
    FROM income_diff      i
    JOIN employment_17    e ON e."zip" = i."zip"
    JOIN zip_state        s ON s."zip" = i."zip"
)
-- 5. state‑level totals
SELECT
    sf."state"                                                AS "state_name",
    ROUND( SUM(z."vul_wholesale")             )               AS "vulnerable_wholesale_trade_workers",
    ROUND( SUM(z."vul_manufact")              )               AS "vulnerable_manufacturing_workers",
    ROUND( SUM(z."vul_wholesale" + z."vul_manufact") )        AS "total_vulnerable_workers"
FROM zip_vulnerable z
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" sf
      ON sf."postal_code" = z."state_code"
GROUP BY sf."state"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;