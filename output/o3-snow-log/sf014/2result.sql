/*  New-York ZIP with the greatest number of >1-hour commuters (ACS 2021)  */
WITH ny_zip_over1hr AS (   -- aggregate 60-89 min (…_011E) and 90+ min (…_012E) commuters by NY ZIP
    SELECT
        f."ZipCode",
        SUM(f."CensusValueByZip") AS "Over1HrCommuters"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"            l
           ON f."ZipCode" = l."ZipCode"
    WHERE  f."MetricID" IN ('B08303_011E', 'B08303_012E')          -- >60-minute commute buckets
      AND  l."PreferredStateAbbrev" = 'NY'
    GROUP BY f."ZipCode"
),
ny_state_over1hr AS (      -- statewide benchmark & population for same two metrics
    SELECT
        SUM("StateBenchmarkValue")        AS "StateBenchmark_Over1Hr",
        MAX("TotalStatePopulation")       AS "NY_StatePopulation"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE  "StateAbbrev" = 'NY'
      AND  "MetricID" IN ('B08303_011E', 'B08303_012E')
)
SELECT
    z."ZipCode",
    z."Over1HrCommuters",
    s."StateBenchmark_Over1Hr",
    s."NY_StatePopulation"
FROM   ny_zip_over1hr      z
CROSS  JOIN ny_state_over1hr s
ORDER  BY z."Over1HrCommuters" DESC NULLS LAST
LIMIT  1;