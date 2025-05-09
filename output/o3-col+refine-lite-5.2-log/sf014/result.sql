WITH ny_zip_over_one_hour AS (   -- 1)  ZIP‑level ≥60‑minute commuters
    SELECT 
        g."ZipCode",
        SUM(f."CensusValueByZip") AS "OverOneHourCommuters"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"            g
           ON f."ZipCode" = g."ZipCode"
    WHERE  g."PreferredStateAbbrev" = 'NY'
      AND  f."MetricID" IN ('B08303_012E', 'B08303_013E')          -- 60‑89 min & 90+ min
    GROUP BY g."ZipCode"
),
top_zip AS (                      -- 2)  ZIP with the highest total
    SELECT 
        "ZipCode",
        "OverOneHourCommuters"
    FROM   ny_zip_over_one_hour
    ORDER BY "OverOneHourCommuters" DESC NULLS LAST, "ZipCode" ASC
    LIMIT 1
),
state_benchmark AS (              -- 3)  NY state benchmark totals
    SELECT 
        SUM("StateBenchmarkValue")  AS "NY_OverOneHour_Benchmark",
        MAX("TotalStatePopulation") AS "NY_StatePopulation"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE  "StateAbbrev" = 'NY'
      AND  "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT 
    z."ZipCode",
    ROUND(z."OverOneHourCommuters", 4)     AS "OverOneHourCommuters",
    ROUND(s."NY_OverOneHour_Benchmark",4)  AS "NY_OverOneHour_Benchmark",
    s."NY_StatePopulation"
FROM   top_zip z
CROSS JOIN state_benchmark s;