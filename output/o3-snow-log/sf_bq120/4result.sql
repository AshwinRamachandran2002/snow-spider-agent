/* Top 10 counties by SNAP-participating households (ACS 2017 5-year),
   plus the ratio of households earning < $20 k to SNAP-households       */

WITH snap_enrollment_201701 AS (        -- SNAP participation on 2017-01-01
    SELECT
        LPAD(SUBSTR("GeoDesc", 1, 5), 5, '0')        AS "county_fips",
        SUM("SNAP_All_Participation_Persons")        AS "snap_persons"
    FROM  SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE "Date" = '2017-01-01'
    GROUP BY "county_fips"
    HAVING "snap_persons" > 0                        -- exclude zero-SNAP
),

county_acs AS (                         -- 2017 ACS 5-year county data
    SELECT
        LPAD(RIGHT("geo_id", 5), 5, '0')                             AS "county_fips",
        "households_public_asst_or_food_stamps"                      AS "snap_households",
        COALESCE("income_less_10000", 0) +
        COALESCE("income_10000_14999", 0) +
        COALESCE("income_15000_19999", 0)                            AS "low_income_households"
    FROM  SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
)

SELECT
    c."county_fips",
    c."snap_households",
    c."low_income_households",
    ROUND( c."low_income_households" / NULLIF(c."snap_households", 0), 4 )
        AS "low_income_to_snap_ratio"
FROM       county_acs              c
INNER JOIN snap_enrollment_201701  s
          ON c."county_fips" = s."county_fips"
WHERE      c."snap_households" > 0
ORDER BY   c."snap_households" DESC NULLS LAST
LIMIT 10;