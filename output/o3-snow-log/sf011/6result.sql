SELECT 
    fc."BlockGroupID",
    fc."CensusValue"                                                    AS "BlockGroup_Pop",
    dg."StateCountyTractID",
    SUM(fc."CensusValue") OVER (PARTITION BY dg."StateCountyTractID")   AS "Total_Tract_Pop",
    ROUND(
        fc."CensusValue"
        / NULLIF(SUM(fc."CensusValue") OVER (PARTITION BY dg."StateCountyTractID"), 0),
        6
    )                                                                   AS "BG_to_Tract_Ratio"
FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021"  fc
JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"        dg
  ON fc."BlockGroupID" = dg."BlockGroupID"
WHERE fc."MetricID" = 'B01003_001E'          -- Total population metric
  AND dg."StateAbbrev" = 'NY';               -- Limit to New York State