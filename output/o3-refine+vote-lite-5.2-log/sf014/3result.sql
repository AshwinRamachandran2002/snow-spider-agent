WITH ny_zip_commuters AS (
    SELECT
        cv."ZipCode",
        cv."CensusValueByZip" AS "Total_Commuters_60MinPlus"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" cv
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" lu
          ON cv."ZipCode" = lu."ZipCode"
    WHERE cv."MetricID" = 'B08303_012E'     -- commuters with travel time ≥ 60 minutes
      AND lu."PreferredStateAbbrev" = 'NY'  -- only New York ZIP codes
)

SELECT
    nz."ZipCode",
    nz."Total_Commuters_60MinPlus",
    sb."StateBenchmarkValue"      AS "NY_State_Commuters_60MinPlus",
    sb."TotalStatePopulation"     AS "NY_State_Population"
FROM ny_zip_commuters nz
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" sb
      ON sb."MetricID"    = 'B08303_012E'
     AND sb."StateAbbrev" = 'NY'
ORDER BY
    nz."Total_Commuters_60MinPlus" DESC NULLS LAST,
    nz."ZipCode"
LIMIT 1;