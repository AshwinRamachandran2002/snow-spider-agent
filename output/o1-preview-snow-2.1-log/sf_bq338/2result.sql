WITH tract_data AS (
    SELECT t."geo_id" AS tract_id, t."tract_name", 
           s2011."total_pop" AS "total_pop_2011", s2018."total_pop" AS "total_pop_2018",
           s2011."median_income" AS "median_income_2011", s2018."median_income" AS "median_income_2018",
           s2018."total_pop" - s2011."total_pop" AS "population_increase",
           s2018."median_income" - s2011."median_income" AS "median_income_increase"
    FROM CENSUS_BUREAU_ACS_1.GEO_CENSUS_TRACTS.CENSUS_TRACTS_NEW_YORK AS t
    JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR AS s2011
        ON t."geo_id" = s2011."geo_id"
    JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR AS s2018
        ON t."geo_id" = s2018."geo_id"
    WHERE t."county_fips_code" = '047'
      AND s2011."total_pop" > 1000 AND s2018."total_pop" > 1000
      AND s2011."median_income" IS NOT NULL AND s2018."median_income" IS NOT NULL
)

SELECT tract_id, "tract_name", "population_increase", "median_income_increase"
FROM (
    SELECT tract_id, "tract_name", "population_increase", "median_income_increase",
           RANK() OVER (ORDER BY "population_increase" DESC NULLS LAST) AS pop_increase_rank,
           RANK() OVER (ORDER BY "median_income_increase" DESC NULLS LAST) AS median_income_increase_rank
        FROM tract_data
) ranked
WHERE pop_increase_rank <= 20 AND median_income_increase_rank <= 20
ORDER BY "population_increase" DESC, "median_income_increase" DESC;