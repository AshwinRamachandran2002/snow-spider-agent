WITH tract17 AS (   -- 2017 tract-level values & adjusted non-labor-force
    SELECT
        t."geo_id",
        -- clamp negative results to 0
        GREATEST(
            0,
            COALESCE(t."unemployed_pop",0)
          + COALESCE(t."not_in_labor_force",0)
          - COALESCE(t."group_quarters",0)
        )                                   AS "adj_nlf",
        t."total_pop"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR"  t
),
income_diff AS (    -- tract-level income change 2015 → 2018
    SELECT
        p15."geo_id",
        p18."median_income" - p15."median_income"  AS "income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR"  p15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR"  p18
          USING ("geo_id")
    WHERE p15."median_income" IS NOT NULL
      AND p18."median_income" IS NOT NULL
),
combined AS (       -- bring 2017 NLF and income change together
    SELECT
        t."geo_id",
        t."adj_nlf",
        t."total_pop",
        d."income_change"
    FROM tract17 t
    JOIN income_diff d
          ON t."geo_id" = d."geo_id"
),
state_agg AS (      -- aggregate to state via 2-digit FIPS prefix
    SELECT
        s."postal_code"                                        AS "state",
        SUM(c."income_change")                                 AS "total_income_diff_2015_2018",
        SUM(c."adj_nlf")                                       AS "total_adj_non_labor_force",
        AVG(c."adj_nlf" / NULLIF(c."total_pop",0))             AS "avg_adj_nlf_proportion"
    FROM combined                     c
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  s
         ON TO_NUMBER(SUBSTR(c."geo_id",1,2)) = s."fips"
    GROUP BY s."postal_code"
)
SELECT
    "state",
    "total_income_diff_2015_2018",
    "total_adj_non_labor_force",
    "avg_adj_nlf_proportion"
FROM state_agg
ORDER BY "total_adj_non_labor_force" ASC
LIMIT 3;