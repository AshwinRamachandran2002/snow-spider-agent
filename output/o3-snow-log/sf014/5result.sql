WITH zip_long_commute AS (
    SELECT
        f."ZipCode",
        SUM(f."CensusValueByZip") AS "Total_Long_Commuters"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"        f
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"                  g
          ON f."ZipCode" = g."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" IN ('B08303_011E','B08303_012E')          -- 60–89 min & 90+ min commuters
    GROUP BY f."ZipCode"
),
ny_benchmark AS (
    SELECT
        SUM(s."StateBenchmarkValue") AS "NY_State_Long_Commuters",
        MAX(s."TotalStatePopulation") AS "NY_State_Population"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
    WHERE s."StateAbbrev" = 'NY'
      AND s."MetricID" IN ('B08303_011E','B08303_012E')          -- same two long-commute metrics
)
SELECT
    z."ZipCode",
    z."Total_Long_Commuters",
    b."NY_State_Long_Commuters",
    b."NY_State_Population"
FROM zip_long_commute z
JOIN ny_benchmark b  ON 1=1
ORDER BY z."Total_Long_Commuters" DESC NULLS LAST
LIMIT 1;