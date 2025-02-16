-- Task: For each census tract in California, calculate the difference in median income between 2015 and 2018. Give me the tract code and the income difference. Limit to 100 rows.
SELECT t1."geo_id", t3."tract_ce", (t2."median_income" - t1."median_income") AS "income_difference"
FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" t1
JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" t2
  ON t1."geo_id" = t2."geo_id"
JOIN CENSUS_BUREAU_ACS_1.GEO_CENSUS_TRACTS."CENSUS_TRACTS_CALIFORNIA" t3
  ON t1."geo_id" = REPLACE(t3."geo_id", '14000US', '')
WHERE t1."median_income" IS NOT NULL AND t2."median_income" IS NOT NULL
LIMIT 100;