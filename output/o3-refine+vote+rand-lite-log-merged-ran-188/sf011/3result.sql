WITH "BG_Pop" AS (   /* 1. 2021 total‑population for every NY block‑group */
    SELECT 
        g."BlockGroupID",
        g."StateCountyTractID",
        COALESCE(f."CensusValue", 0)             AS "BlockGroupPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"   = 'B01003_001E'   -- Total population
      AND g."StateAbbrev" = 'NY'           -- New York State only
), 
"Tract_Pop" AS (      /* 2. Sum the block‑group values to the tract level */
    SELECT 
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TractPopulation"
    FROM "BG_Pop"
    GROUP BY "StateCountyTractID"
)
SELECT
    b."BlockGroupID",
    b."BlockGroupPopulation",
    b."StateCountyTractID",
    t."TractPopulation",
    CASE 
        WHEN t."TractPopulation" = 0 THEN NULL
        ELSE ROUND(b."BlockGroupPopulation" / t."TractPopulation", 4)
    END AS "PopulationRatioBGtoTract"
FROM "BG_Pop" b
JOIN "Tract_Pop" t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    b."StateCountyTractID",
    b."BlockGroupID";