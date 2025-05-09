WITH increases AS (
  SELECT 
    t2011."geo_id" AS "tract_id",
    ctracts."tract_name",
    (t2018."total_pop" - t2011."total_pop") AS "population_increase",
    (t2018."median_income" - t2011."median_income") AS "median_income_increase",
    RANK() OVER (ORDER BY (t2018."total_pop" - t2011."total_pop") DESC NULLS LAST) AS "pop_rank",
    RANK() OVER (ORDER BY (t2018."median_income" - t2011."median_income") DESC NULLS LAST) AS "income_rank"
  FROM 
    "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2011_5YR" AS t2011
  JOIN 
    "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" AS t2018
    ON t2011."geo_id" = t2018."geo_id"
  JOIN 
    "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK" AS ctracts
    ON t2011."geo_id" = ctracts."geo_id"
  WHERE 
    t2011."geo_id" LIKE '36047%'
    AND t2011."total_pop" > 1000 
    AND t2018."total_pop" > 1000
)
SELECT 
  "tract_id",
  "tract_name",
  ROUND("population_increase", 4) AS "population_increase",
  ROUND("median_income_increase", 4) AS "median_income_increase"
FROM 
  increases
WHERE 
  "pop_rank" <= 20 AND "income_rank" <= 20
ORDER BY 
  "pop_rank";