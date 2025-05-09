SELECT 
    FZ."ZipCode",
    FZ."CensusValueByZip"                         AS "Commuters_Over_1_Hour",
    FS."StateBenchmarkValue"                      AS "NY_State_Benchmark_Over_1_Hour",
    FS."TotalStatePopulation"                     AS "NY_Total_State_Population"
FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  FZ
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"             LU
      ON FZ."ZipCode" = LU."ZipCode"
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"      FS
      ON FS."MetricID"    = 'B08303_013E'   -- “60 or more minutes” commute
     AND FS."StateAbbrev" = 'NY'
WHERE FZ."MetricID"            = 'B08303_013E'   -- “60 or more minutes” commute
  AND LU."PreferredStateAbbrev" = 'NY'           -- keep only New York ZIP codes
ORDER BY 
      FZ."CensusValueByZip" DESC NULLS LAST, 
      FZ."ZipCode"
LIMIT 1;