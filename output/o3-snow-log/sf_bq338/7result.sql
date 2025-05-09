/*  Tracts in county 36047 that are simultaneously
    1) in the top-20 for % population growth (2011-2018)
    2) in the top-20 for absolute median-income growth (2011-2018)
    3) had >1,000 residents in both 2011 and 2018                                   */

WITH tract_2011 AS (      /* 2011 tract-level figures */
    SELECT  "geo_id"                       AS "tract_id",
            "total_pop"                    AS "pop2011",
            "median_income"                AS "medinc2011"
    FROM    CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR
    WHERE   LEFT("geo_id",5) = '36047'            -- county 36047
      AND   "total_pop" > 1000                    -- pop filter
),
tract_2018 AS (      /* 2018 figures aggregated from block groups to tracts */
    SELECT  SUBSTR("geo_id",1,11)                 AS "tract_id",
            SUM("total_pop")                      AS "pop2018",
            SUM("median_income" * "total_pop")
            / NULLIF(SUM("total_pop"),0)          AS "medinc2018"
    FROM    CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE   LEFT("geo_id",5) = '36047'
    GROUP BY 1
    HAVING  SUM("total_pop") > 1000               -- pop filter
),
joined AS (        /* combine years & calculate changes */
    SELECT  t11."tract_id",
            t11."pop2011",
            t18."pop2018",
            (t18."pop2018" - t11."pop2011") / t11."pop2011"      AS "pop_pct_change",
            t11."medinc2011",
            t18."medinc2018",
            (t18."medinc2018" - t11."medinc2011")                AS "medinc_abs_change"
    FROM    tract_2011 t11
    JOIN    tract_2018 t18
      ON    t11."tract_id" = t18."tract_id"
    WHERE   t11."medinc2011" IS NOT NULL
      AND   t18."medinc2018" IS NOT NULL
),
pop_top20 AS (     /* top 20 by % population growth */
    SELECT  "tract_id"
    FROM    joined
    ORDER BY "pop_pct_change" DESC NULLS LAST
    LIMIT   20
),
inc_top20 AS (     /* top 20 by absolute median-income growth */
    SELECT  "tract_id"
    FROM    joined
    ORDER BY "medinc_abs_change" DESC NULLS LAST
    LIMIT   20
)
SELECT  j."tract_id",
        j."pop2011",
        j."pop2018",
        j."pop_pct_change",
        j."medinc2011",
        j."medinc2018",
        j."medinc_abs_change"
FROM    joined j
WHERE   j."tract_id" IN (
        SELECT  p."tract_id"
        FROM    pop_top20 p
        JOIN    inc_top20 i
          ON    p."tract_id" = i."tract_id"
)
ORDER BY j."tract_id";