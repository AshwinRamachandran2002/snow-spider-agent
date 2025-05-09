/*  Population distribution of every New-York (StateFIPS = '36') block-group
    versus the total population of its parent Census-tract               */

SELECT
        g."BlockGroupID",
        f."CensusValue"                                                   AS "BlockGroupPopulation",
        g."StateCountyTractID",
        SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")   AS "TotalTractPopulation",
        ROUND(
              f."CensusValue"
              / NULLIF(SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"),0)
              , 6
        )                                                                 AS "PopulationRatio_BG_to_Tract"
FROM    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"      g
JOIN    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" f
          ON f."BlockGroupID" = g."BlockGroupID"
WHERE   g."StateFIPS" = '36'                      -- New York
  AND   f."MetricID"  = 'B01003_001E'             -- Total population metric
ORDER BY
        g."StateCountyTractID",
        g."BlockGroupID";