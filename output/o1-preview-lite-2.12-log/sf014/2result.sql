WITH TotalStateBenchmark AS (
    SELECT
        SUM("StateBenchmarkValue") AS "StateBenchmark",
        MAX("TotalStatePopulation") AS "StatePopulation"
    FROM
        CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE
        "StateAbbrev" = 'NY'
        AND "MetricID" IN ('B08303_011E', 'B08303_012E')
)
SELECT
    f."ZipCode",
    ROUND(SUM(f."CensusValueByZip"), 4) AS "TotalCommuters",
    tsb."StateBenchmark",
    tsb."StatePopulation"
FROM
    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" l
        ON f."ZipCode" = l."ZipCode"
    CROSS JOIN TotalStateBenchmark tsb
WHERE
    l."PreferredStateAbbrev" = 'NY'
    AND f."MetricID" IN ('B08303_011E', 'B08303_012E')
GROUP BY
    f."ZipCode", tsb."StateBenchmark", tsb."StatePopulation"
ORDER BY
    SUM(f."CensusValueByZip") DESC NULLS LAST
LIMIT 1;