SELECT
    g."BlockGroupID",
    f."CensusValue"                                                   AS "BlockGroupPop",
    g."StateCountyTractID",
    SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")   AS "TractTotalPop",
    ROUND(
        f."CensusValue" /
        NULLIF(
            SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"),
            0
        ),
        6
    )                                                                 AS "PopRatio_BG_to_Tract"
FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"   f
JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"         g
       ON f."BlockGroupID" = g."BlockGroupID"
WHERE  f."MetricID"    = 'B01003_001E'   -- Total population
  AND  g."StateAbbrev" = 'NY'
ORDER BY g."StateCountyTractID",
         g."BlockGroupID";