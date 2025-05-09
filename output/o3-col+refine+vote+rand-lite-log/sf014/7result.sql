/* New York ZIP with the most commuters whose one-way travel-time to work exceeds one hour,
   along with statewide comparison figures from the 2021 ACS. */
SELECT
    z."ZipCode",
    z."Total_Over1Hr_Commuters",
    s."NY_Total_Over1Hr_Commuters",
    s."NY_Total_Population"
FROM (
        /* --- ZIP-level totals (sum of 60-89 min + 90 + min buckets) --- */
        SELECT
            f."ZipCode",
            SUM(f."CensusValueByZip") AS "Total_Over1Hr_Commuters"
        FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
        JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
              ON f."ZipCode" = g."ZipCode"
        WHERE g."PreferredStateAbbrev" = 'NY'
          AND f."MetricID" IN ('B08303_013E',   -- 60-89 minutes
                               'B08303_014E')   -- 90 or more minutes
        GROUP BY f."ZipCode"
        ORDER BY "Total_Over1Hr_Commuters" DESC NULLS LAST
        LIMIT 1
     ) z
CROSS JOIN (
        /* --- Statewide benchmark for the same two commute buckets --- */
        SELECT
            SUM("StateBenchmarkValue") AS "NY_Total_Over1Hr_Commuters",
            MIN("TotalStatePopulation") AS "NY_Total_Population"
        FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
        WHERE "StateAbbrev" = 'NY'
          AND "MetricID" IN ('B08303_013E',
                             'B08303_014E')
     ) s;