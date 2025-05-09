/* New York ZIP with the most commuters travelling > 1 hour, plus state context */
WITH zip_totals AS (
    SELECT
        g."ZipCode",
        SUM(f."CensusValueByZip") AS "Total_Over1Hr_Commuters"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"            g
          ON f."ZipCode" = g."ZipCode"
    WHERE f."MetricID" IN ('B08303_012E', 'B08303_013E')           -- 60–89 min & 90+ min
      AND g."PreferredStateAbbrev" = 'NY'
    GROUP BY g."ZipCode"
),
ny_benchmark AS (
    SELECT
        SUM("StateBenchmarkValue") AS "NY_Over1Hr_Benchmark",
        MAX("TotalStatePopulation") AS "NY_Total_Pop"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT
    z."ZipCode",
    z."Total_Over1Hr_Commuters",
    b."NY_Over1Hr_Benchmark",
    b."NY_Total_Pop"
FROM zip_totals z
CROSS JOIN ny_benchmark b
ORDER BY z."Total_Over1Hr_Commuters" DESC NULLS LAST
LIMIT 1;