-- Population distribution of each New York block group relative to its census tract (ACS 2021)
SELECT
    f."BlockGroupID",
    f."CensusValue"                                                   AS "BlockGroupPopulation",
    g."StateCountyTractID",
    SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")   AS "TotalTractPopulation",
    ROUND(
        f."CensusValue" /
        NULLIF( SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"), 0 )
    , 6)                                                              AS "BlockGroup_To_Tract_Ratio"
FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
       ON f."BlockGroupID" = g."BlockGroupID"
WHERE  f."MetricID"   = 'B01003_001E'   -- Total population metric
  AND  g."StateAbbrev" = 'NY';