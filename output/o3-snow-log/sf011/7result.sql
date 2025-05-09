/*  Population share of each New York block group within its parent census tract (ACS 2021)
    – safeguarded against division-by-zero                                     */

WITH block_group_counts AS (      -- block-group level population
    SELECT
        dg."BlockGroupID",
        dg."StateCountyTractID",
        fc."CensusValue"                          AS "BlockGroupPopulation"
    FROM  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  fc
    JOIN  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"         dg
          ON dg."BlockGroupID" = fc."BlockGroupID"
    WHERE fc."MetricID"    = 'B01003_001E'        -- Total population
      AND dg."StateAbbrev" = 'NY'                 -- New York only
),

tract_totals AS (                 -- tract-level totals
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM   block_group_counts
    GROUP  BY "StateCountyTractID"
)

SELECT
    bg."BlockGroupID",
    bg."BlockGroupPopulation"                 AS "CensusValue",
    bg."StateCountyTractID",
    tt."TotalTractPopulation",
    ROUND( bg."BlockGroupPopulation"
           / NULLIF(tt."TotalTractPopulation", 0), 6)  AS "PopulationRatio"
FROM         block_group_counts bg
INNER JOIN   tract_totals       tt
       ON    bg."StateCountyTractID" = tt."StateCountyTractID"
WHERE        tt."TotalTractPopulation" <> 0            -- ensure safe division
ORDER BY     "PopulationRatio" DESC NULLS LAST;