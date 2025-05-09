WITH tract_level AS (
    SELECT
        /* two–digit state FIPS taken from the tract GEOID */
        LEFT(t17."geo_id", 2)                                                AS "state_fips_code",

        /* adjusted non-labor-force population, clamped at zero              */
        GREATEST(
            0,
            COALESCE(t17."unemployed_pop",0)
          + COALESCE(t17."not_in_labor_force",0)
          - COALESCE(t17."group_quarters",0)
        )                                                                    AS "adj_nlf_2017",

        /* tract population (needed for proportion)                          */
        COALESCE(t17."total_pop",0)                                          AS "total_pop",

        /* change in median household income: 2018 minus 2015                */
        (t18."median_income" - t15."median_income")                          AS "income_change_15_18"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR  t17
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR  t15
          ON t17."geo_id" = t15."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR  t18
          ON t17."geo_id" = t18."geo_id"
    /* keep only tracts where both income figures exist                      */
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
)

SELECT
    sf."postal_code"                                                         AS "state_abbrev",
    SUM(tl."income_change_15_18")                                            AS "total_income_change",
    SUM(tl."adj_nlf_2017")                                                   AS "total_adj_nlf",
    AVG( CASE WHEN tl."total_pop" > 0                                        -- avoid divide-by-zero
              THEN tl."adj_nlf_2017" / tl."total_pop"
         END )                                                               AS "avg_adj_nlf_prop"
FROM tract_level tl
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
      ON LPAD(sf."fips", 2, '0') = tl."state_fips_code"
GROUP BY sf."postal_code"
ORDER BY "total_adj_nlf" ASC
LIMIT 3;