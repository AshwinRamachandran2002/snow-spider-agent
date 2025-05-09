WITH "ny_zip_long" AS (
    SELECT 
        z."ZipCode",
        SUM(z."CensusValueByZip") AS "TotalCommuters_60plus"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" z
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
          ON z."ZipCode" = g."ZipCode"
    WHERE z."MetricID" IN ('B08303_012E', 'B08303_013E')   -- 60–89 min and 90+ min commuters
      AND g."PreferredStateAbbrev" = 'NY'
    GROUP BY z."ZipCode"
), "top_zip" AS (
    SELECT 
        "ZipCode",
        "TotalCommuters_60plus"
    FROM "ny_zip_long"
    ORDER BY "TotalCommuters_60plus" DESC NULLS LAST
    LIMIT 1
), "ny_state" AS (
    SELECT
        SUM("StateBenchmarkValue")  AS "NY_LongCommute_Benchmark",
        MAX("TotalStatePopulation") AS "NY_TotalPopulation"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT
    t."ZipCode",
    t."TotalCommuters_60plus",
    s."NY_LongCommute_Benchmark",
    s."NY_TotalPopulation"
FROM "top_zip" t
CROSS JOIN "ny_state" s;