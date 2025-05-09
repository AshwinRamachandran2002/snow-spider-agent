/*  Top-3 states with the smallest 2017 adjusted non-labor-force totals  */
WITH base AS (   /* tracts that have both 2015 & 2018 median-income values */
    SELECT
        t17."geo_id",
        SUBSTR(t17."geo_id",1,2)                                                  AS state_fips,
        COALESCE(t17."unemployed_pop",0)
      + COALESCE(t17."not_in_labor_force",0)
      - COALESCE(t17."group_quarters",0)                                          AS raw_adj_nlf,
        t17."total_pop"                                                           AS total_pop,   -- give explicit alias
        t18."median_income" - t15."median_income"                                 AS income_diff
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR" t17
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" t15
          ON t15."geo_id" = t17."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" t18
          ON t18."geo_id" = t17."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
),
metrics AS (   /* clamp negatives to zero & build tract-level ratios */
    SELECT
        state_fips,
        CASE WHEN raw_adj_nlf < 0 THEN 0 ELSE raw_adj_nlf END                     AS adj_nlf,
        total_pop,
        income_diff,
        CASE
            WHEN total_pop > 0
            THEN (CASE WHEN raw_adj_nlf < 0 THEN 0 ELSE raw_adj_nlf END) / total_pop
        END                                                                       AS nlf_ratio
    FROM base
)
SELECT
    sf."postal_code"                                                              AS state,
    SUM(m.income_diff)                                                            AS total_income_change,
    SUM(m.adj_nlf)                                                                AS total_adjusted_nlf,
    AVG(m.nlf_ratio)                                                              AS avg_adjusted_nlf_ratio
FROM metrics m
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" sf
     ON LPAD(TO_CHAR(sf."fips"),2,'0') = m.state_fips
GROUP BY sf."postal_code"
ORDER BY total_adjusted_nlf ASC
LIMIT 3;