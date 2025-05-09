/*  Population share of every NY block group relative to its parent census tract (ACS-2021) */
WITH tract_totals AS (
    SELECT
        g."StateCountyTractID",
        SUM(f."CensusValue") AS "TotalTractPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"    = 'B01003_001E'          -- total population
      AND g."StateAbbrev" = 'NY'                   -- New-York only
    GROUP BY g."StateCountyTractID"
)

SELECT
    f."BlockGroupID",
    f."CensusValue"                           AS "BlockGroupPopulation",
    g."StateCountyTractID",
    t."TotalTractPopulation",
    ROUND(
        f."CensusValue" / NULLIF(t."TotalTractPopulation",0)
      , 4)                                    AS "BlockGroupToTractRatio"
FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       g
      ON f."BlockGroupID" = g."BlockGroupID"
JOIN tract_totals t
      ON g."StateCountyTractID" = t."StateCountyTractID"
WHERE f."MetricID"    = 'B01003_001E'
  AND g."StateAbbrev" = 'NY'
ORDER BY
    g."StateCountyTractID",
    "BlockGroupToTractRatio" DESC NULLS LAST;