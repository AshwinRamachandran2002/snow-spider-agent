SELECT 
       f."ZipCode",
       f."CensusValueByZip"           AS "TotalCommutersOverOneHour",
       s."StateBenchmarkValue",
       s."TotalStatePopulation"
FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"             l
       ON f."ZipCode" = l."ZipCode"
JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"      s
       ON s."MetricID"      = f."MetricID"
      AND s."StateAbbrev"   = 'NY'
WHERE  f."MetricID"             = 'B08303_013E'      -- commuters ≥60 minutes
  AND  l."PreferredStateAbbrev" = 'NY'               -- focus on New York ZIPs
ORDER BY f."CensusValueByZip" DESC NULLS LAST
LIMIT 1;