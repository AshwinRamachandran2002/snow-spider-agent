WITH state_bench AS (
    SELECT 
        "StateBenchmarkValue",
        "TotalStatePopulation"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" = 'B08303_012E'           -- 60 minutes or more travel‑time to work
), ny_zip_commuters AS (
    SELECT 
        f."ZipCode",
        CAST(f."CensusValueByZip" AS FLOAT) AS "TotalCommuters_Over1Hour"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded"             g
      ON f."ZipCode" = g."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" = 'B08303_012E'        -- 60 minutes or more travel‑time to work
)
SELECT 
    nzc."ZipCode",
    nzc."TotalCommuters_Over1Hour",
    sb."StateBenchmarkValue"      AS "NY_State_Benchmark_Over1Hour",
    sb."TotalStatePopulation"     AS "NY_State_Population"
FROM ny_zip_commuters nzc
CROSS JOIN state_bench sb
ORDER BY nzc."TotalCommuters_Over1Hour" DESC NULLS LAST, nzc."ZipCode"
LIMIT 1;