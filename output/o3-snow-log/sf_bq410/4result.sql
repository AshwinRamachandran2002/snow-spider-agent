/* ----------------------------------------------------------------------
   Top 3 states with the smallest adjusted non-labor-force population
   using 2017 ACS block-group data
------------------------------------------------------------------------*/
WITH income_change AS (          -- 1. 2018 – 2015 median-income change
    SELECT
        bg18."geo_id",
        bg18."median_income" - bg15."median_income" AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR  AS bg18
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR  AS bg15
          ON bg18."geo_id" = bg15."geo_id"
    WHERE bg18."median_income" IS NOT NULL
      AND bg15."median_income" IS NOT NULL
),
nlf_2017 AS (                    -- 2. 2017 adjusted non-labor-force counts
    SELECT
        bg17."geo_id",
        bg17."total_pop",
        /* Only "not_in_labor_force" available for 2017 table */
        GREATEST(COALESCE(bg17."not_in_labor_force", 0), 0) AS adjusted_nlf
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR AS bg17
),
tract_level AS (                 -- 3. merge income-change with 2017 NLF data
    SELECT
        ic."geo_id",
        ic.income_change,
        nlf."total_pop",
        nlf.adjusted_nlf,
        LEFT(ic."geo_id", 2) AS state_fips                     -- first 2 digits
    FROM income_change AS ic
    JOIN nlf_2017     AS nlf
      ON ic."geo_id" = nlf."geo_id"
)
SELECT
    sf."postal_code"                                         AS state_abbrev,
    SUM(tl.income_change)                                    AS total_median_income_change,
    SUM(tl.adjusted_nlf)                                     AS total_adjusted_non_labor_force,
    AVG(
        CASE WHEN tl."total_pop" > 0
             THEN tl.adjusted_nlf / tl."total_pop"
        END
    )                                                        AS avg_population_adjusted_proportion
FROM tract_level AS tl
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS AS sf
  ON sf."fips" = TO_NUMBER(tl.state_fips)
GROUP BY sf."postal_code"
ORDER BY total_adjusted_non_labor_force ASC
LIMIT 3;