WITH "ny_zip_commuters" AS (
    SELECT
        f."ZipCode",
        SUM(f."CensusValueByZip") AS "TotalCommutersOver1Hour"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded"             g
          ON f."ZipCode" = g."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" IN ('B08303_012E',   -- 60–89 minutes
                           'B08303_013E')   -- 90 or more minutes
    GROUP BY f."ZipCode"
),
"max_zip" AS (
    SELECT
        "ZipCode",
        "TotalCommutersOver1Hour"
    FROM "ny_zip_commuters"
    ORDER BY "TotalCommutersOver1Hour" DESC NULLS LAST, "ZipCode"
    LIMIT 1
),
"state_benchmark" AS (
    SELECT
        SUM("StateBenchmarkValue") AS "StateBenchmarkOver1Hour",
        MAX("TotalStatePopulation") AS "TotalStatePopulation"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT
    mz."ZipCode",
    mz."TotalCommutersOver1Hour",
    sb."StateBenchmarkOver1Hour",
    sb."TotalStatePopulation"
FROM "max_zip" mz
CROSS JOIN "state_benchmark" sb;