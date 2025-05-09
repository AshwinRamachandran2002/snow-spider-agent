WITH tract_totals AS (
    SELECT
        g."StateCountyTractID" AS "state_county_tract_id",
        SUM(f."CensusValue")   AS "total_tract_population"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" AS f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       AS g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"    = 'B01003_001E'   -- Total population
      AND g."StateAbbrev" = 'NY'            -- New York State
    GROUP BY g."StateCountyTractID"
)

SELECT
    f."BlockGroupID"                             AS "block_group_id",
    f."CensusValue"                              AS "census_value",
    g."StateCountyTractID"                       AS "state_county_tract_id",
    t."total_tract_population",
    ROUND(f."CensusValue" / NULLIF(t."total_tract_population", 0), 4) AS "population_ratio"
FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" AS f
JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       AS g
      ON f."BlockGroupID" = g."BlockGroupID"
JOIN tract_totals t
      ON t."state_county_tract_id" = g."StateCountyTractID"
WHERE f."MetricID"    = 'B01003_001E'
  AND g."StateAbbrev" = 'NY'
ORDER BY
    g."StateCountyTractID",
    f."BlockGroupID";