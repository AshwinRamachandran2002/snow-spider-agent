/* New York ZIP code with the greatest number of commuters travelling 60-plus minutes (ACS 2021) */
SELECT
    f."ZipCode"                                                    AS "ZipCode",
    f."CensusValueByZip"                                           AS "TotalCommuters_60plus_Minutes",
    s."StateBenchmarkValue"                                        AS "NY_StateBenchmark_60plus_Minutes",
    s."TotalStatePopulation"                                       AS "NY_StatePopulation_2021"
FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"             g
           ON f."ZipCode" = g."ZipCode"
JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"      s
           ON s."MetricID"    = f."MetricID"
          AND s."StateAbbrev" = 'NY'
WHERE  f."MetricID"              = 'B08303_013E'   -- commuters with travel time ≥60 min (ACS table B08303)
  AND  g."PreferredStateAbbrev"  = 'NY'
ORDER BY
       f."CensusValueByZip" DESC NULLS LAST
LIMIT 1;