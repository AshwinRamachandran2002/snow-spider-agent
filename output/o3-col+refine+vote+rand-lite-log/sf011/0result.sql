/* ---------------------------------------------------------------
   Population share of every New-York block group within its tract
   ---------------------------------------------------------------
   • MetricID ‘B01003_001E’ = Total Population (ACS-2021)
   • Calculates each tract’s total then each block-group’s ratio
-----------------------------------------------------------------*/
WITH ny_tract_pop AS (
    SELECT
        g."StateCountyTractID",
        SUM(f."CensusValue") AS "TractTotalPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
      ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"    = 'B01003_001E'      -- total population
      AND g."StateAbbrev" = 'NY'               -- New-York only
    GROUP BY g."StateCountyTractID"
    HAVING SUM(f."CensusValue") > 0            -- avoid zero-denominator tracts
)

SELECT
    g."BlockGroupID",
    f."CensusValue"              AS "BlockGroupPopulation",
    g."StateCountyTractID",
    t."TractTotalPopulation",
    ROUND(
        f."CensusValue" / t."TractTotalPopulation", 4
    )                            AS "PopulationRatio_BG_to_Tract"
FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
  ON f."BlockGroupID" = g."BlockGroupID"
JOIN ny_tract_pop t
  ON g."StateCountyTractID" = t."StateCountyTractID"
WHERE f."MetricID"    = 'B01003_001E'
  AND g."StateAbbrev" = 'NY'
ORDER BY
    g."StateCountyTractID",
    g."BlockGroupID";