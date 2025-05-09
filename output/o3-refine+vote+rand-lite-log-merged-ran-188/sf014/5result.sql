SELECT 
    f."ZipCode",
    f."CensusValueByZip"                       AS "TotalCommuters_Over1Hr",
    sb."StateBenchmarkValue"                  AS "StateBenchmark_Over1Hr",
    sb."TotalStatePopulation"
FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"              lu
      ON f."ZipCode" = lu."ZipCode"
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"       sb
      ON f."MetricID" = sb."MetricID"
     AND sb."StateAbbrev" = 'NY'
WHERE f."MetricID" = 'B08303_012E'          -- 60 or more minutes to work
  AND lu."PreferredStateAbbrev" = 'NY'      -- restrict to New York ZIP codes
ORDER BY f."CensusValueByZip" DESC NULLS LAST,
         f."ZipCode"           ASC
LIMIT 1;