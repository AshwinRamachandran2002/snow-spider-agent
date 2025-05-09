WITH "zip_commuters" AS (
    SELECT 
        f."ZipCode",
        SUM(f."CensusValueByZip") AS "TotalCommutersOver1Hr"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip" f
    JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded" z
          ON f."ZipCode" = z."ZipCode"
    WHERE z."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" IN ('B08303_012E', 'B08303_013E')   -- 60–89 min & 90+ min commute buckets
    GROUP BY f."ZipCode"
),
"state_benchmark" AS (
    SELECT 
        SUM("StateBenchmarkValue") AS "StateBenchmarkCommutersOver1Hr",
        MAX("TotalStatePopulation") AS "TotalStatePopulation"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT 
    zc."ZipCode",
    zc."TotalCommutersOver1Hr",
    sb."StateBenchmarkCommutersOver1Hr",
    sb."TotalStatePopulation"
FROM "zip_commuters" zc
CROSS JOIN "state_benchmark" sb
ORDER BY zc."TotalCommutersOver1Hr" DESC NULLS LAST
LIMIT 1;