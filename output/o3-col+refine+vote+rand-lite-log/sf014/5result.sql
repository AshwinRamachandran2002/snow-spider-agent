WITH ny_long_commute AS (
    SELECT 
        g."ZipCode",
        SUM(f."CensusValueByZip") AS "CommutersOverHour"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
          ON f."ZipCode" = g."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND f."MetricID" IN ('B08303_012E', 'B08303_013E')          -- 60–89 & 90+ minutes
    GROUP BY g."ZipCode"
    ORDER BY "CommutersOverHour" DESC NULLS LAST
    LIMIT 1
), ny_benchmark AS (
    SELECT 
        SUM("StateBenchmarkValue")  AS "NY_BenchmarkOverHour",   -- statewide commuters > 1 hour
        MAX("TotalStatePopulation") AS "TotalStatePopulation"    -- 2021 NY population
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT 
    c."ZipCode",
    c."CommutersOverHour",
    b."NY_BenchmarkOverHour",
    b."TotalStatePopulation"
FROM ny_long_commute c
CROSS JOIN ny_benchmark b;