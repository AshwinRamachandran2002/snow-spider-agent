/* Population distribution of every New-York block group relative to its parent
   census tract – ACS-2021 “Total Population”                                    */

WITH ny_blockgroup_pop AS (
    SELECT
        f."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"    = 'B01003_001E'   -- Total population
      AND g."StateAbbrev" = 'NY'            -- New-York State only
)

SELECT
    "BlockGroupID",
    "StateCountyTractID",
    "CensusValue"                                                   AS "BlockGroupPopulation",
    SUM("CensusValue") OVER (PARTITION BY "StateCountyTractID")     AS "TotalTractPopulation",
    "CensusValue" /
    NULLIF(SUM("CensusValue") OVER (PARTITION BY "StateCountyTractID"), 0)  AS "PopulationRatio"
FROM ny_blockgroup_pop
ORDER BY "StateCountyTractID", "BlockGroupID";