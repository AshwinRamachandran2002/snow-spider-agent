/*  Top-10 counties (ACS 2017 5-YR) with the largest number of SNAP-participating
    households and the ratio of households earning < $20 K to those SNAP households */

WITH county_acs AS (            -- 2017 5-year ACS county-level households data
    SELECT
        RIGHT("geo_id", 5)                                            AS "FIPS5",
        "households_public_asst_or_food_stamps"                       AS "SNAP_HH",
        ("income_less_10000" + "income_10000_14999" + "income_15000_19999")
                                                                      AS "HH_UNDER_20K"
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
),
snap_enrollment AS (            -- SNAP enrollment on 01-Jan-2017 (persons)
    SELECT
        LEFT("GeoDesc", 5)                                            AS "FIPS5",
        SUM("SNAP_All_Participation_Persons")                         AS "SNAP_PERS"
    FROM SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE "Date" = '2017-01-01'
    GROUP BY LEFT("GeoDesc", 5)
)
SELECT
    ca."FIPS5",
    ca."SNAP_HH"                                   AS "TOTAL_SNAP_HOUSEHOLDS",
    ca."HH_UNDER_20K",
    ROUND( ca."HH_UNDER_20K" / NULLIF(ca."SNAP_HH", 0), 4 )
                                                   AS "UNDER20K_TO_SNAP_RATIO"
FROM county_acs ca
JOIN snap_enrollment se
  ON ca."FIPS5" = se."FIPS5"
WHERE ca."SNAP_HH" > 0
ORDER BY ca."SNAP_HH" DESC NULLS LAST
LIMIT 10;