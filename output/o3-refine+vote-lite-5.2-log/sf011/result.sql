WITH base AS (
    SELECT
        g."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue" AS "BlockGroupPopulation"
    FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography"  g
    JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" f
      ON g."BlockGroupID" = f."BlockGroupID"
    WHERE g."StateAbbrev" = 'NY'
      AND f."MetricID"    = 'B01003_001E'      -- Total population metric
),    

tract_totals AS (
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TractTotalPopulation"
    FROM base
    GROUP BY "StateCountyTractID"
)

SELECT
    b."BlockGroupID",
    b."BlockGroupPopulation"                       AS "CensusValue",
    b."StateCountyTractID",
    t."TractTotalPopulation",
    CASE 
        WHEN t."TractTotalPopulation" = 0 THEN NULL
        ELSE b."BlockGroupPopulation" / t."TractTotalPopulation"
    END AS "PopulationRatioBlockGroupToTract"
FROM base b
JOIN tract_totals t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    b."StateCountyTractID",
    b."BlockGroupID";