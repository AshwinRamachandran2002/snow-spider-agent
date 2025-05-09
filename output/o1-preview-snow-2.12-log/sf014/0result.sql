SELECT t."ZipCode", ROUND(SUM(t."CensusValueByZip"), 4) AS "TotalCommuters",
    (
        SELECT ROUND(SUM(s."StateBenchmarkValue"), 4)
        FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
        WHERE s."MetricID" IN ('B08303_012E', 'B08303_013E') AND s."StateAbbrev" = 'NY'
    ) AS "StateBenchmark",
    (
        SELECT MAX(s."TotalStatePopulation")
        FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
        WHERE s."StateAbbrev" = 'NY'
    ) AS "StatePopulation"
FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" t
JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
    ON t."ZipCode" = g."ZipCode"
WHERE t."MetricID" IN ('B08303_012E', 'B08303_013E') AND g."PreferredStateAbbrev" = 'NY'
GROUP BY t."ZipCode"
ORDER BY "TotalCommuters" DESC NULLS LAST
LIMIT 1;