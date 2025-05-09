SELECT 
    f."BlockGroupID", 
    ROUND(f."CensusValue", 4) AS "CensusValue",
    g."StateCountyTractID",
    ROUND(t."TotalTractPopulation", 4) AS "TotalTractPopulation",
    ROUND(f."CensusValue" / NULLIF(t."TotalTractPopulation", 0), 4) AS "PopulationRatio"
FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" AS f
JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography" AS g
    ON f."BlockGroupID" = g."BlockGroupID"
JOIN (
    SELECT 
        g."StateCountyTractID", 
        SUM(f."CensusValue") AS "TotalTractPopulation"
    FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" AS f
    JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography" AS g
        ON f."BlockGroupID" = g."BlockGroupID"
    WHERE g."StateAbbrev" = 'NY' AND f."MetricID" = 'B11012_001E'
    GROUP BY g."StateCountyTractID"
) AS t ON g."StateCountyTractID" = t."StateCountyTractID"
WHERE g."StateAbbrev" = 'NY' AND f."MetricID" = 'B11012_001E';