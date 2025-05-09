WITH ny_zip_commute AS (
    SELECT 
        f."ZipCode",
        SUM(f."CensusValueByZip") AS "OverOneHourCommuters"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"            g
      ON f."ZipCode" = g."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" IN ('B08303_012E',   -- 60‑89 minutes
                           'B08303_013E')   -- 90+  minutes
    GROUP BY f."ZipCode"
),
state_benchmark AS (
    SELECT 
        SUM("StateBenchmarkValue")      AS "StateBenchmarkOverOneHour",
        MAX("TotalStatePopulation")     AS "TotalStatePopulation"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E',
                         'B08303_013E')
)
SELECT 
    z."ZipCode",
    z."OverOneHourCommuters",
    s."StateBenchmarkOverOneHour",
    s."TotalStatePopulation"
FROM ny_zip_commute z
CROSS JOIN state_benchmark s
ORDER BY z."OverOneHourCommuters" DESC NULLS LAST,
         z."ZipCode"
LIMIT 1;