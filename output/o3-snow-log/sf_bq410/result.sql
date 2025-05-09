/*--------------------------------------------------------------------
  Compute the three states with the smallest adjusted non-labor-force
  population using 2017 tract-level (block-group) data.
--------------------------------------------------------------------*/
WITH bg17 AS (       /*-------------- 1.  2017 tract data --------------*/
    SELECT
        "geo_id",
        "total_pop"            AS total_pop,            -- rename to UC
        "not_in_labor_force"   AS not_in_labor_force,   -- rename to UC
        CAST(0 AS FLOAT)       AS unemployed_pop,       -- placeholder
        CAST(0 AS FLOAT)       AS group_quarters        -- placeholder
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR
),

income15 AS (        /*-------------- 2.  2015 median income -----------*/
    SELECT
        "geo_id",
        "median_income" AS median_income_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR
),
income18 AS (        /*-------------- 3.  2018 median income -----------*/
    SELECT
        "geo_id",
        "median_income" AS median_income_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
),

income_change AS (   /*-------------- 4.  income difference ------------*/
    SELECT
        i18."geo_id",
        i18.median_income_2018 - i15.median_income_2015 AS income_diff
    FROM income18 i18
    JOIN income15 i15
      ON i18."geo_id" = i15."geo_id"
    WHERE i18.median_income_2018 IS NOT NULL
      AND i15.median_income_2015 IS NOT NULL
),

combined AS (        /*-------------- 5.  merge 2017 + income ----------*/
    SELECT
        b17."geo_id",
        b17.total_pop,
        b17.not_in_labor_force,
        b17.unemployed_pop,
        b17.group_quarters,
        ic.income_diff,
        TO_NUMBER(SUBSTR(b17."geo_id", 1, 2)) AS state_fips
    FROM bg17 b17
    JOIN income_change ic
      ON b17."geo_id" = ic."geo_id"
),

calc AS (            /*-------------- 6.  adjusted NLF & proportion ----*/
    SELECT
        c.*,
        COALESCE(unemployed_pop,0)
          + COALESCE(not_in_labor_force,0)
          - COALESCE(group_quarters,0)                               AS raw_adj_nlf,

        CASE
            WHEN COALESCE(unemployed_pop,0)
                 + COALESCE(not_in_labor_force,0)
                 - COALESCE(group_quarters,0) < 0                    THEN 0
            ELSE COALESCE(unemployed_pop,0)
                 + COALESCE(not_in_labor_force,0)
                 - COALESCE(group_quarters,0)
        END                                                          AS adjusted_nlf,

        CASE
            WHEN total_pop IS NULL OR total_pop = 0                  THEN NULL
            ELSE
                CASE
                    WHEN COALESCE(unemployed_pop,0)
                         + COALESCE(not_in_labor_force,0)
                         - COALESCE(group_quarters,0) < 0            THEN 0
                    ELSE COALESCE(unemployed_pop,0)
                         + COALESCE(not_in_labor_force,0)
                         - COALESCE(group_quarters,0)
                END / total_pop
        END                                                          AS prop_adj
    FROM combined c
),

state_agg AS (       /*-------------- 7.  aggregate to state -----------*/
    SELECT
        sf."postal_code"                       AS state_abbrev,
        SUM(calc.income_diff)                  AS total_median_income_change,
        SUM(calc.adjusted_nlf)                 AS total_adjusted_non_labor_force,
        AVG(calc.prop_adj)                     AS avg_population_adjusted_proportion
    FROM calc
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
      ON calc.state_fips = sf."fips"
    GROUP BY sf."postal_code"
)

SELECT                /*-------------- 8.  final result ----------------*/
    state_abbrev,
    total_median_income_change,
    total_adjusted_non_labor_force,
    avg_population_adjusted_proportion
FROM state_agg
ORDER BY total_adjusted_non_labor_force ASC
FETCH FIRST 3 ROWS ONLY;