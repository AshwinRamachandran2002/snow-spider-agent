WITH state_names AS (
    SELECT
        LPAD("state_fips_code", 2, '0')           AS "state_fips",
        MIN("state_name")                         AS "state_name"
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
    GROUP BY LPAD("state_fips_code", 2, '0')
),
vulnerable AS (
    SELECT
        LPAD("geo_id", 2, '0')                                         AS "state_fips",
        ROUND("employed_wholesale_trade" * 0.38, 4)                    AS "vulnerable_wholesale_workers",
        ROUND("employed_manufacturing"  * 0.41, 4)                     AS "vulnerable_manufacturing_workers"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_1YR
)
SELECT
    COALESCE(n."state_name", v."state_fips")                           AS "state",
    v."vulnerable_wholesale_workers",
    v."vulnerable_manufacturing_workers",
    ROUND(v."vulnerable_wholesale_workers" + 
          v."vulnerable_manufacturing_workers", 4)                     AS "total_vulnerable_workers"
FROM vulnerable v
LEFT JOIN state_names n
       ON v."state_fips" = n."state_fips"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST, "state";