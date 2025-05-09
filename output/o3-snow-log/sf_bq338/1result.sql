/*  Tracts in Kings County (FIPS 36047) that are
    – top-20 in % population increase (2011→2018)
    – top-20 in absolute median-income increase (2011→2018)
    – have >1,000 residents in both 2011 & 2018
*/

WITH trg_2018 AS (           -- aggregate 2018 block-groups to tract level
    SELECT
        SUBSTR("geo_id", 1, 11)       AS "tract_id",
        SUM("total_pop")              AS "pop_2018",
        AVG("median_income")          AS "income_2018"
    FROM
        CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE
        "geo_id" LIKE '36047%'        -- Kings County
    GROUP BY
        SUBSTR("geo_id", 1, 11)
),

metrics AS (                -- join to 2011 tract table & compute changes
    SELECT
        t11."geo_id"                         AS "tract_id",
        t11."total_pop"                      AS "pop_2011",
        trg_2018."pop_2018",
        (trg_2018."pop_2018" - t11."total_pop")
            / NULLIF(t11."total_pop", 0)     AS "pct_pop_change",
        t11."median_income"                  AS "income_2011",
        trg_2018."income_2018",
        trg_2018."income_2018"
            - t11."median_income"            AS "income_change"
    FROM
        CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR  t11
        JOIN trg_2018
          ON t11."geo_id" = trg_2018."tract_id"
    WHERE
        t11."geo_id" LIKE '36047%'           -- Kings County
        AND t11."total_pop"  > 1000
        AND trg_2018."pop_2018" > 1000
),

ranked AS (                 -- rank tracts by each metric
    SELECT
        *,
        RANK() OVER (ORDER BY "pct_pop_change" DESC NULLS LAST)  AS "pop_rank",
        RANK() OVER (ORDER BY "income_change"  DESC NULLS LAST)  AS "income_rank"
    FROM metrics
)

SELECT
    "tract_id",
    "pop_2011",
    "pop_2018",
    "pct_pop_change",
    "income_2011",
    "income_2018",
    "income_change",
    "pop_rank",
    "income_rank"
FROM
    ranked
WHERE
      "pop_rank"   <= 20     -- top 20 in % pop increase
  AND "income_rank"<= 20     -- top 20 in absolute income increase
ORDER BY
    "pop_rank",
    "income_rank";