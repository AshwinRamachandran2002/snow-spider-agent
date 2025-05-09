/*  Top 10 counties (ACS 2017 5-YR) with the largest number of SNAP-participating households
    and the ratio of households earning < $20 000 to total SNAP households                */

WITH county_acs_2017 AS (          /* 2017 5-year ACS county-level data */
    SELECT
        RIGHT("geo_id", 5)                                   AS county_fips,           -- 5-digit county FIPS
        "households_public_asst_or_food_stamps"              AS snap_households,       -- SNAP-participating households
        ("income_less_10000" +
         "income_10000_14999" +
         "income_15000_19999")                              AS households_under_20k
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
),
snap_enrollment_2017 AS (          /* SNAP enrolment as of 1-Jan-2017 */
    SELECT
        SUBSTR("GeoDesc", 1, 5)                              AS county_fips,           -- 5-digit county FIPS
        SUM("SNAP_All_Participation_Persons")                AS snap_persons
    FROM SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE "Date" = '2017-01-01'
    GROUP BY SUBSTR("GeoDesc", 1, 5)
),
combined AS (                      /* merge ACS households with enrolment persons  */
    SELECT
        a.county_fips,
        a.snap_households,
        COALESCE(e.snap_persons, 0)                         AS snap_persons,
        a.households_under_20k,
        (a.snap_households + COALESCE(e.snap_persons, 0))   AS total_snap_participation
    FROM county_acs_2017 a
    LEFT JOIN snap_enrollment_2017 e
           ON a.county_fips = e.county_fips
)
SELECT
    county_fips                                                   AS "county_fips",
    total_snap_participation                                      AS "total_snap_participating_households",
    ROUND(
        households_under_20k / NULLIF(total_snap_participation, 0),
        4
    )                                                             AS "ratio_under_20000_to_snap"
FROM combined
WHERE total_snap_participation > 0
ORDER BY total_snap_participation DESC NULLS LAST
LIMIT 10;