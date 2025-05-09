WITH "BG_Population" AS (
    /* 1. 2021 ACS total‑population for every block group */
    SELECT
        f."BlockGroupID",
        f."CensusValue" AS "BlockGroupPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" f
    WHERE f."MetricID" = 'B01003_001E'
),
"BG_With_Tract" AS (
    /* 2. Attach tract‑ID and keep only New York State block groups */
    SELECT
        bp."BlockGroupID",
        bp."BlockGroupPopulation",
        g."StateCountyTractID"
    FROM "BG_Population" bp
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" g
      ON bp."BlockGroupID" = g."BlockGroupID"
    WHERE g."StateAbbrev" = 'NY'
),
"Tract_Totals" AS (
    /* 3. Total population of each New York census tract */
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM "BG_With_Tract"
    GROUP BY "StateCountyTractID"
)

SELECT
    b."BlockGroupID",
    b."BlockGroupPopulation"                       AS "CensusValue",
    b."StateCountyTractID",
    t."TotalTractPopulation",
    b."BlockGroupPopulation" / NULLIF(t."TotalTractPopulation", 0) AS "PopulationRatio"
FROM "BG_With_Tract" b
JOIN "Tract_Totals" t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    b."StateCountyTractID",
    b."BlockGroupID";