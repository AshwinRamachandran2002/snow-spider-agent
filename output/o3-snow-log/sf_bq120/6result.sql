/* 1)  Get county–level SNAP-enrollment (persons) observed on 2017-01-01.
      Keep the first 5 characters of “GeoDesc” – this is the county FIPS code. */
WITH snap_201701 AS (
    SELECT
        LEFT("GeoDesc", 5)        AS county_fips,
        SUM("SNAP_All_Participation_Persons") AS snap_persons
    FROM SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE "Date" = '2017-01-01'
    GROUP BY county_fips
),

/* 2)  Pull the 2017 5-year ACS county data, keeping the same
       5-digit county FIPS code (last 5 characters of GEOID).           */
county_acs AS (
    SELECT
        RIGHT("geo_id", 5)                                AS county_fips,
        "geo_id",
        "households_public_asst_or_food_stamps"           AS snap_households,
        COALESCE("income_less_10000",      0)
      + COALESCE("income_10000_14999",     0)
      + COALESCE("income_15000_19999",     0)             AS under_20k_households
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
),

/* 3)  Combine the two sources, keeping only counties that have
       non-zero SNAP-participating households *and* appear in the
       2017-01-01 SNAP file.                                           */
combined AS (
    SELECT
        a."geo_id",
        a.county_fips,
        a.snap_households                    AS total_snap_households,
        a.under_20k_households,
        s.snap_persons
    FROM county_acs a
    INNER JOIN snap_201701 s
            ON a.county_fips = s.county_fips
    WHERE a.snap_households > 0
)

/* 4)  Return the 10 counties with the largest number of
       SNAP-participating households and their under-$20k ratio.       */
SELECT
    "geo_id"                                          AS county_geo_id,
    total_snap_households,
    under_20k_households,
    ROUND(under_20k_households / total_snap_households, 4)
        AS ratio_under20k_to_snap_households
FROM combined
ORDER BY total_snap_households DESC NULLS LAST
LIMIT 10;