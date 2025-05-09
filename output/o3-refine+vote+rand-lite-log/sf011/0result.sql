WITH block_group_pop AS (          -- 1. 2021 ACS total‑population for every block group
    SELECT  F."BlockGroupID",
            F."CensusValue" AS "BlockGroupPopulation"
    FROM    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" F
    WHERE   F."MetricID" = 'B01003_001E'           -- “Total population”
),
bg_geo AS (                        -- 2. New York block groups with their tract IDs
    SELECT  B."BlockGroupID",
            B."BlockGroupPopulation",
            G."StateCountyTractID"
    FROM    block_group_pop B
    JOIN    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" G
           ON B."BlockGroupID" = G."BlockGroupID"
    WHERE   G."StateAbbrev" = 'NY'
),
tract_totals AS (                  -- 3. Total population per tract
    SELECT  "StateCountyTractID",
            SUM("BlockGroupPopulation") AS "TractPopulation"
    FROM    bg_geo
    GROUP BY "StateCountyTractID"
)

SELECT  BG."BlockGroupID",
        BG."BlockGroupPopulation"                 AS "CensusValue",
        BG."StateCountyTractID",
        TT."TractPopulation",
        ROUND(
            BG."BlockGroupPopulation" / NULLIF(TT."TractPopulation", 0), 
            4
        )                                         AS "PopulationRatio"
FROM    bg_geo        BG
JOIN    tract_totals  TT
      ON BG."StateCountyTractID" = TT."StateCountyTractID"
ORDER BY BG."StateCountyTractID",
         BG."BlockGroupID";