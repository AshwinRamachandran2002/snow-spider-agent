WITH tract_totals AS (
    SELECT
        g."StateCountyTractID",
        SUM(f."CensusValue") AS "TotalTractPopulation"
    FROM
        CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" f
    JOIN
        CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" g
        ON f."BlockGroupID" = g."BlockGroupID"
    WHERE
        f."MetricID" = 'B01003_001E' AND
        g."StateAbbrev" = 'NY'
    GROUP BY
        g."StateCountyTractID"
    HAVING
        SUM(f."CensusValue") > 0
)
SELECT
    f."BlockGroupID",
    f."CensusValue",
    g."StateCountyTractID",
    t."TotalTractPopulation",
    ROUND(f."CensusValue" / t."TotalTractPopulation", 4) AS "PopulationRatio"
FROM
    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" f
JOIN
    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" g
    ON f."BlockGroupID" = g."BlockGroupID"
JOIN
    tract_totals t
    ON g."StateCountyTractID" = t."StateCountyTractID"
WHERE
    f."MetricID" = 'B01003_001E' AND
    g."StateAbbrev" = 'NY'
ORDER BY
    g."StateCountyTractID" ASC,
    f."BlockGroupID" ASC;