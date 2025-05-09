SELECT 
       topzip."ZipCode",
       topzip."Long_Commutes",
       statebench."State_Long_Commutes",
       statebench."NY_State_Pop_2021"
FROM  (
        SELECT 
               g."ZipCode",
               SUM(f."CensusValueByZip") AS "Long_Commutes"
        FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"   f
        JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"              g
               ON f."ZipCode" = g."ZipCode"
        WHERE  g."PreferredStateAbbrev" = 'NY'
          AND  f."MetricID" IN ('B08303_013E','B08303_014E')   -- >1-hour commute buckets
        GROUP  BY g."ZipCode"
        ORDER  BY "Long_Commutes" DESC NULLS LAST
        LIMIT  1
) topzip
CROSS JOIN (
        SELECT 
               SUM(s."StateBenchmarkValue") AS "State_Long_Commutes",
               MAX(s."TotalStatePopulation") AS "NY_State_Pop_2021"
        FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
        WHERE  s."StateAbbrev" = 'NY'
          AND  s."MetricID" IN ('B08303_013E','B08303_014E')   -- align with ZIP-level buckets
) statebench;