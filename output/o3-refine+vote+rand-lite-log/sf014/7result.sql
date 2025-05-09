SELECT
    fv."ZipCode",
    fv."CensusValueByZip"            AS "TotalCommuters_Over1Hr",
    sb."StateBenchmarkValue"         AS "StateBenchmark_Over1Hr",
    sb."TotalStatePopulation"
FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"   fv
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"              lu
      ON fv."ZipCode" = lu."ZipCode"
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"       sb
      ON sb."MetricID"       = fv."MetricID"
     AND sb."StateAbbrev"    = lu."PreferredStateAbbrev"
WHERE fv."MetricID"              = 'B08303_011E'         -- Commute time: 60 minutes or more
  AND lu."PreferredStateAbbrev"  = 'NY'                  -- New York State ZIP codes
ORDER BY CAST(fv."CensusValueByZip" AS FLOAT) DESC NULLS LAST
LIMIT 1;