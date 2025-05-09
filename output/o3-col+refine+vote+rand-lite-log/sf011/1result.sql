/*  Population distribution for every NY block-group (ACS 2021)               */
/*  – returns BlockGroupID, its population, parent-tract ID & total,          */
/*    plus the block-group’s share of that tract (rounded to 4 decimals)      */

WITH bg AS (      -- all New-York block-groups carrying the “Total Population” metric
    SELECT
        f."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue" AS "BlockGroupPopulation"
    FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
           ON f."BlockGroupID" = g."BlockGroupID"
    WHERE  f."MetricID"    = 'B01003_001E'     -- Total Population
      AND  g."StateAbbrev" = 'NY'
),

tract_totals AS ( -- total population for each NY census-tract
    SELECT
        g."StateCountyTractID",
        SUM(f."CensusValue") AS "TotalTractPopulation"
    FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
           ON f."BlockGroupID" = g."BlockGroupID"
    WHERE  f."MetricID"    = 'B01003_001E'
      AND  g."StateAbbrev" = 'NY'
    GROUP  BY g."StateCountyTractID"
    HAVING SUM(f."CensusValue") > 0            -- ignore any zero-population tracts
)

SELECT
       bg."StateCountyTractID",
       bg."BlockGroupID",
       bg."BlockGroupPopulation"                       AS "CensusValue",
       tt."TotalTractPopulation",
       ROUND( bg."BlockGroupPopulation"
              / NULLIF(tt."TotalTractPopulation", 0)
            , 4)                                      AS "PopulationRatio"
FROM   bg
JOIN   tract_totals tt
       ON bg."StateCountyTractID" = tt."StateCountyTractID"
ORDER  BY
       bg."StateCountyTractID",
       bg."BlockGroupID";