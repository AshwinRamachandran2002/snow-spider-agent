-- Task: List the top 100 ZIP codes in New York State along with the total number of commuters traveling over one hour for each, according to 2021 ACS data.
SELECT
    GE."ZipCode",
    SUM(
        CASE WHEN M."MetricID" = 'B08303_013E' THEN F."CensusValueByZip" ELSE 0 END +
        CASE WHEN M."MetricID" = 'B08303_012E' THEN F."CensusValueByZip" ELSE 0 END
    ) AS "Num_Commuters_1Hr_Travel_Time"
FROM
    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" GE
JOIN
    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" F
    ON GE."ZipCode" = F."ZipCode"
JOIN
    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Dim_CensusMetrics" M
    ON F."MetricID" = M."MetricID"
WHERE
    GE."PreferredStateAbbrev" = 'NY'
    AND M."MetricID" IN ('B08303_013E', 'B08303_012E')
GROUP BY
    GE."ZipCode"
ORDER BY
    "Num_Commuters_1Hr_Travel_Time" DESC
LIMIT 100;