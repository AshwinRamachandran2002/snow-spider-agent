/*  Population distribution of each New-York block group relative to its Census tract – ACS 2021  */
SELECT
       g."BlockGroupID",
       f."CensusValue"                                                   AS "BlockGroupPopulation",
       g."StateCountyTractID",
       /* tract-level total (window sum) */
       SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")   AS "TotalTractPopulation",
       /* share of the tract that the block group represents */
       ROUND(
             f."CensusValue" /
             NULLIF( SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"), 0 )
       , 4)                                                              AS "BlockGroupToTractRatio"
FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"   g
JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" f
       ON g."BlockGroupID" = f."BlockGroupID"
WHERE  g."StateFIPS"  = '36'              -- New York
  AND  f."MetricID"  = 'B01003_001E'      -- Total population
ORDER BY g."StateCountyTractID",
         g."BlockGroupID";