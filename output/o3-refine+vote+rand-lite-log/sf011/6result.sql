WITH "BG_POP" AS (
    SELECT
        f."BlockGroupID",
        g."StateCountyTractID",
        CAST(f."CensusValue" AS FLOAT) AS "BlockGroupPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"   = 'B01003_001E'          -- Total population metric
      AND g."StateAbbrev" = 'NY'                  -- New York State only
)

SELECT
    "BlockGroupID",
    "StateCountyTractID",
    "BlockGroupPopulation"               AS "CensusValue",
    SUM("BlockGroupPopulation") 
        OVER (PARTITION BY "StateCountyTractID") AS "TotalTractPopulation",
    "BlockGroupPopulation" / NULLIF(
        SUM("BlockGroupPopulation") 
            OVER (PARTITION BY "StateCountyTractID"), 0
    )                                          AS "PopulationRatio_BG_to_Tract"
FROM "BG_POP"
ORDER BY "StateCountyTractID", "BlockGroupID";