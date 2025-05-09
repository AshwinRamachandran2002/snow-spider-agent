WITH ny_zip_commuters AS (
    SELECT
        f."ZipCode",
        f."CensusValueByZip"::FLOAT AS "Over1Hr_Commuters"
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip" f
    JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded" g
      ON f."ZipCode" = g."ZipCode"
    WHERE f."MetricID" = 'B08303_011E'          -- commuters ≥60 minutes
      AND g."PreferredStateAbbrev" = 'NY'       -- New York ZIP codes only
), top_zip AS (
    SELECT
        "ZipCode",
        "Over1Hr_Commuters"
    FROM ny_zip_commuters
    ORDER BY "Over1Hr_Commuters" DESC NULLS LAST
    LIMIT 1                                       -- highest-value NY ZIP
)
SELECT
    t."ZipCode",
    t."Over1Hr_Commuters"        AS "Total_Commuters_60+Min",
    s."StateBenchmarkValue"      AS "NY_State_Benchmark_60+Min",
    s."TotalStatePopulation"     AS "NY_Total_Population_2021"
FROM top_zip t
CROSS JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021" s
WHERE s."MetricID"   = 'B08303_011E'
  AND s."StateAbbrev" = 'NY';