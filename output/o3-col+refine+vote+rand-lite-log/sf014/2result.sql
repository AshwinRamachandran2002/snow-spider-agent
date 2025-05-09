WITH zip_totals AS (   -- 1)  Sum 60–89 min and 90+ min commuters for every NY ZIP
    SELECT
           f."ZipCode",
           SUM(f."CensusValueByZip") AS "Total_Commuters_Over1Hour"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"             g
           ON f."ZipCode" = g."ZipCode"
    WHERE  f."MetricID" IN ('B08303_012E',   -- 60–89 minutes
                            'B08303_013E')   -- 90 + minutes
      AND  g."PreferredStateAbbrev" = 'NY'
    GROUP  BY f."ZipCode"
),
ny_benchmark AS (      -- 2)  Statewide total and population for the same two metrics
    SELECT
           SUM(s."StateBenchmarkValue")  AS "NY_Benchmark_Over1Hour",
           MAX(s."TotalStatePopulation") AS "TotalStatePopulation"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
    WHERE  s."StateAbbrev" = 'NY'
      AND  s."MetricID"    IN ('B08303_012E','B08303_013E')
)
-- 3)  Return the single NY ZIP with the highest ≥1-hour commuter count
SELECT 
       z."ZipCode",
       z."Total_Commuters_Over1Hour",
       b."NY_Benchmark_Over1Hour",
       b."TotalStatePopulation"
FROM   zip_totals   z
CROSS  JOIN ny_benchmark b
ORDER  BY z."Total_Commuters_Over1Hour" DESC NULLS LAST
LIMIT 1;