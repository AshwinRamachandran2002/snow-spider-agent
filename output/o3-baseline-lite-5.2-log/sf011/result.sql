/*  Population distribution of every New‑York block group
    relative to the population of its parent census tract
    (ACS 2021, MetricID = B01003_001E “Total Population”) */

WITH ny_block_group_pop AS (
    SELECT
        g."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue"  AS "BlockGroupPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"  = 'B01003_001E'         -- total population metric
      AND g."StateAbbrev" = 'NY'                -- New‑York only
),

tract_totals AS (
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM ny_block_group_pop
    GROUP BY "StateCountyTractID"
)

SELECT
    b."BlockGroupID",
    b."BlockGroupPopulation"          AS "CensusValue",
    b."StateCountyTractID",
    t."TotalTractPopulation",
    CASE
        WHEN t."TotalTractPopulation" = 0 THEN NULL
        ELSE b."BlockGroupPopulation" / t."TotalTractPopulation"
    END                               AS "PopulationRatio"
FROM ny_block_group_pop b
JOIN tract_totals   t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    b."StateCountyTractID",
    b."BlockGroupID";