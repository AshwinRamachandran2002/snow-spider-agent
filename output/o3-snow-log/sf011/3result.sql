/*  Population distribution of every New York block-group relative to its parent census tract
    – 2021 ACS “Total population” (MetricID = B01003_001E)                              */

WITH tract_tot AS (
    SELECT  g."StateCountyTractID",
            SUM(f."CensusValue")  AS "TotalTractPopulation"
    FROM    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  f
    JOIN    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"        g
            ON f."BlockGroupID" = g."BlockGroupID"
    WHERE   f."MetricID"   = 'B01003_001E'          -- Total population
      AND   g."StateAbbrev" = 'NY'                  -- New York only
    GROUP BY g."StateCountyTractID"
)

SELECT  g."BlockGroupID",
        f."CensusValue"                 AS "BlockGroupPopulation",
        g."StateCountyTractID",
        t."TotalTractPopulation",
        ROUND( f."CensusValue" / NULLIF(t."TotalTractPopulation",0), 5 )
                                        AS "BlockGroupToTractRatio"
FROM    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  f
JOIN    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"        g
        ON f."BlockGroupID" = g."BlockGroupID"
JOIN    tract_tot t
        ON t."StateCountyTractID" = g."StateCountyTractID"
WHERE   f."MetricID"   = 'B01003_001E'
  AND   g."StateAbbrev" = 'NY'
ORDER BY g."StateCountyTractID",
         g."BlockGroupID";