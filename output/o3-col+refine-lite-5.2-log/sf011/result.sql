SELECT
    dg."BlockGroupID",
    fc."CensusValue"                                                  AS "BlockGroupPopulation",
    dg."StateCountyTractID",
    SUM(fc."CensusValue") OVER (PARTITION BY dg."StateCountyTractID") AS "TotalTractPopulation",
    fc."CensusValue" / NULLIF(SUM(fc."CensusValue") 
           OVER (PARTITION BY dg."StateCountyTractID"), 0)            AS "PopulationRatio"
FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  fc
JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       dg
      ON fc."BlockGroupID" = dg."BlockGroupID"
WHERE dg."StateAbbrev" = 'NY'
  AND fc."MetricID"   = 'B01003_001E'
ORDER BY dg."StateCountyTractID", dg."BlockGroupID";