SELECT
    f."BlockGroupID"                                                   AS block_group_id,
    f."CensusValue"                                                    AS census_value,
    g."StateCountyTractID"                                             AS state_county_tract_id,
    SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID")    AS total_tract_population,
    ROUND(
        f."CensusValue" /
        NULLIF(SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"), 0)
    , 4)                                                               AS population_ratio
FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  f
JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"        g
  ON f."BlockGroupID" = g."BlockGroupID"
WHERE f."MetricID"  = 'B01003_001E'     -- Total population metric
  AND g."StateFIPS" = '36'              -- New York State
QUALIFY SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID") > 0
ORDER BY g."StateCountyTractID", f."BlockGroupID";