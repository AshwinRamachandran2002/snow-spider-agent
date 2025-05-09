-- population distribution of each NY block group relative to its census tract (ACS 2021)
SELECT
    g."BlockGroupID",
    f."CensusValue"                                                             AS "BlockGroupPop",
    g."StateCountyTractID",
    SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")             AS "TotalTractPop",
    ROUND(
        f."CensusValue" / NULLIF( SUM(f."CensusValue") 
                                  OVER (PARTITION BY g."StateCountyTractID"), 0)
    , 6)                                                                        AS "PopRatio_BG_to_Tract"
FROM  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  AS f
JOIN  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       AS g
      ON f."BlockGroupID" = g."BlockGroupID"
WHERE f."MetricID"    = 'B01003_001E'   -- Total population metric
  AND g."StateAbbrev" = 'NY'            -- restrict to New York State
ORDER BY
      g."StateCountyTractID",
      "PopRatio_BG_to_Tract" DESC NULLS LAST;