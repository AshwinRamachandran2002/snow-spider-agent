SELECT  
        z."ZipCode",
        z."TotalCommuters_Over1Hr",
        sb."NY_StateBenchmark_Over1Hr",
        sb."NY_StatePopulation"
FROM   (
        /*––– ZIP-level totals for commuters whose travel time ≥60 minutes –––*/
        SELECT  f."ZipCode",
                SUM(f."CensusValueByZip") AS "TotalCommuters_Over1Hr"
        FROM    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"   f
        JOIN    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"              g
               ON f."ZipCode" = g."ZipCode"
        WHERE   g."PreferredStateAbbrev" = 'NY'
          AND   f."MetricID" IN ('B08303_012E', 'B08303_013E')   -- 60-89 min & 90+ min buckets
        GROUP BY f."ZipCode"
        QUALIFY ROW_NUMBER() OVER (ORDER BY SUM(f."CensusValueByZip") DESC NULLS LAST) = 1
      )  z
CROSS JOIN (
        /*––– State-wide benchmark & population for the same ≥60-minute commuters –––*/
        SELECT  SUM("StateBenchmarkValue") AS "NY_StateBenchmark_Over1Hr",
                MAX("TotalStatePopulation") AS "NY_StatePopulation"
        FROM    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
        WHERE   "StateAbbrev" = 'NY'
          AND   "MetricID" IN ('B08303_012E', 'B08303_013E')
      )  sb;