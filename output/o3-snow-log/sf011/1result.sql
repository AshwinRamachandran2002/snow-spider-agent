/* -----------------------------------------------------------
   Population share of every New York block-group within its
   parent Census tract – ACS 2021 “Total Population”
----------------------------------------------------------- */
WITH block_group_population AS (
    /* 1.  Pull 2021 total-population for each NY block group   */
    SELECT
        f."BlockGroupID",
        f."CensusValue"                AS "BlockGroupPopulation",
        g."StateCountyTractID"
    FROM   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"        f
    JOIN   CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"              g
           ON f."BlockGroupID" = g."BlockGroupID"
    WHERE  f."MetricID"   = 'B01003_001E'          -- Total population
      AND  g."StateAbbrev" = 'NY'                  -- New York State only
),
tract_totals AS (
    /* 2.  Aggregate those block-group counts up to the tract  */
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation")    AS "TotalTractPopulation"
    FROM   block_group_population
    GROUP  BY "StateCountyTractID"
)

/* 3.  Combine block-group rows with their tract totals & ratio */
SELECT
    bg."BlockGroupID",
    bg."BlockGroupPopulation"          AS "CensusValue",
    bg."StateCountyTractID",
    tr."TotalTractPopulation",
    ROUND(
        bg."BlockGroupPopulation"
        / NULLIF(tr."TotalTractPopulation",0),      -- safe divide
        6                                           -- 6-decimal precision
    )                               AS "PopulationRatio"
FROM   block_group_population  bg
JOIN   tract_totals            tr
       ON bg."StateCountyTractID" = tr."StateCountyTractID"
WHERE  tr."TotalTractPopulation" <> 0               -- exclude zero-pop tracts
ORDER  BY bg."StateCountyTractID", bg."BlockGroupID";