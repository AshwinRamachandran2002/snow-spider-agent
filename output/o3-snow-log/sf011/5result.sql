/* ---------------------------------------------------------------------------
   Population distribution of each New-York Block-Group relative to its parent
   Census Tract – 2021 ACS “Total Population” metric (B01003_001E)
   --------------------------------------------------------------------------- */
WITH tract_tot AS (
    SELECT
        g."StateCountyTractID",
        SUM(f."CensusValue") AS "TotalTractPopulation"
    FROM
        "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  f
        JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"   g
              ON f."BlockGroupID" = g."BlockGroupID"
    WHERE
        g."StateAbbrev" = 'NY'                -- New York only
        AND f."MetricID" = 'B01003_001E'      -- Total population
    GROUP BY
        g."StateCountyTractID"
)

SELECT
    g."BlockGroupID",
    f."CensusValue"                                          AS "BlockGroupPopulation",
    g."StateCountyTractID",
    t."TotalTractPopulation",
    f."CensusValue" / NULLIF(t."TotalTractPopulation", 0)    AS "PopulationRatio_BG_to_Tract"
FROM
    "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  f
    JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"   g
          ON f."BlockGroupID" = g."BlockGroupID"
    JOIN tract_tot t
          ON g."StateCountyTractID" = t."StateCountyTractID"
WHERE
    g."StateAbbrev" = 'NY'
    AND f."MetricID"  = 'B01003_001E'
ORDER BY
    g."StateCountyTractID",
    g."BlockGroupID";