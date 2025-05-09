SELECT f."BlockGroupID",
       f."CensusValue",
       g."StateCountyTractID",
       SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID") AS "TotalTractPopulation",
       ROUND((f."CensusValue" / NULLIF(SUM(f."CensusValue") OVER (PARTITION BY g."StateCountyTractID"), 0)), 4) AS "PopulationRatio"
FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" AS f
JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography" AS g
  ON f."BlockGroupID" = g."BlockGroupID"
WHERE g."StateAbbrev" = 'NY' AND f."MetricID" = 'B01003_001E'
;