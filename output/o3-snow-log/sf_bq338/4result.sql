WITH t2018 AS (   -- 2018 tract-level figures built from block-groups
    SELECT 
        SUBSTR("geo_id",1,11)                                   AS "tract_geoid",
        SUM("total_pop")                                        AS "pop2018",
        SUM("median_income" * "total_pop") / NULLIF(SUM("total_pop"),0)
                                                                AS "median_income2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '36047%'                 -- Kings County, NY
    GROUP BY SUBSTR("geo_id",1,11)
),

joined AS (        -- combine 2011 & 2018 stats, keep only tracts ≥1 000 pop both years
    SELECT 
        t11."geo_id"                                          AS "tract_geoid",
        t11."total_pop"                                       AS "pop2011",
        t18."pop2018",
        (t18."pop2018" - t11."total_pop") * 100.0 
            / NULLIF(t11."total_pop",0)                      AS "pop_pct_change",
        t11."median_income"                                   AS "inc2011",
        t18."median_income2018",
        (t18."median_income2018" - t11."median_income")       AS "inc_abs_change"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR t11
    JOIN t2018 t18
          ON t11."geo_id" = t18."tract_geoid"
    WHERE t11."geo_id"   LIKE '36047%'
      AND t11."total_pop" >= 1000
      AND t18."pop2018"   >= 1000
),

ranked AS (        -- rank by % pop increase and by absolute income increase
    SELECT 
        j.*,
        ROW_NUMBER() OVER (ORDER BY j."pop_pct_change"  DESC NULLS LAST) AS "pop_rank",
        ROW_NUMBER() OVER (ORDER BY j."inc_abs_change" DESC NULLS LAST) AS "inc_rank"
    FROM joined j
)

-- final list: tracts that are TOP-20 on BOTH rankings
SELECT 
    "tract_geoid",
    "pop2011",
    "pop2018",
    "pop_pct_change",
    "inc2011",
    "median_income2018",
    "inc_abs_change"
FROM ranked
WHERE "pop_rank" <= 20
  AND "inc_rank" <= 20
ORDER BY "tract_geoid";