/* ---------------------------------------------------------------
   Top-3 states with the smallest adjusted non-labor-force pop
   ---------------------------------------------------------------*/
WITH inc_change AS (   /* 1. block-group median-income change 15→18 */
    SELECT  t15."geo_id",
            (t18."median_income" - t15."median_income")  AS income_diff
    FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR  t15
    JOIN    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR  t18
           ON t18."geo_id" = t15."geo_id"
    WHERE   t15."median_income" IS NOT NULL
      AND   t18."median_income" IS NOT NULL
), /* ----------------------------------------------------------- */
tract17 AS (           /* 2. 2017 block-group data + income change  */
    SELECT  bg17."geo_id"                                           AS geo_id,
            SUBSTR(bg17."geo_id",1,2)                               AS state_fips,
            COALESCE(bg17."total_pop",0)                            AS total_pop,
            COALESCE(bg17."not_in_labor_force",0)                   AS not_in_labor_force,
            0                                                       AS unemployed_pop,   -- column not available
            0                                                       AS group_quarters,   -- column not available
            ic.income_diff                                          AS income_diff
    FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR bg17
    JOIN    inc_change ic  ON ic."geo_id" = bg17."geo_id"
), /* ----------------------------------------------------------- */
tract_metrics AS (     /* 3. adjusted non-labor & proportion         */
    SELECT  state_fips,
            GREATEST(unemployed_pop + not_in_labor_force - group_quarters,0)  AS adj_non_labor,
            total_pop,
            income_diff,
            CASE 
                WHEN total_pop > 0 THEN 
                     GREATEST(unemployed_pop + not_in_labor_force - group_quarters,0)::FLOAT
                     / total_pop
            END                                                          AS tract_prop
    FROM    tract17
), /* ----------------------------------------------------------- */
state_metrics AS (     /* 4. aggregate to state level                */
    SELECT  sf."postal_code"                                            AS state_abbrev,
            SUM(income_diff)                                            AS total_median_income_change,
            SUM(adj_non_labor)                                          AS total_adjusted_non_labor,
            AVG(tract_prop)                                             AS avg_population_adjusted_proportion
    FROM    tract_metrics tm
    JOIN    CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
          ON LPAD(TO_VARCHAR(sf."fips"),2,'0') = tm.state_fips
    GROUP BY sf."postal_code"
) /* ------------------------------------------------------------ */
SELECT  state_abbrev,
        total_median_income_change,
        total_adjusted_non_labor,
        avg_population_adjusted_proportion
FROM    state_metrics
ORDER BY total_adjusted_non_labor ASC
LIMIT 3;