/* Population distribution of each NY block group within its census tract – ACS 2021 (handles zero‑population tracts) */
WITH BlockGroup_Pop AS (
    /* 1. Block‑group level population (MetricID = 'B01003_001E' -> Total Population) */
    SELECT
        f."BlockGroupID",
        CAST(f."CensusValue" AS FLOAT) AS "BlockGroupPopulation"
    FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" AS f
    WHERE f."MetricID" = 'B01003_001E'
),
NY_BlockGroups AS (
    /* 2. Keep only New York block groups and attach their census‑tract IDs */
    SELECT
        g."BlockGroupID",
        g."StateCountyTractID",
        p."BlockGroupPopulation"
    FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography" AS g
    JOIN BlockGroup_Pop AS p
          ON g."BlockGroupID" = p."BlockGroupID"
    WHERE g."StateAbbrev" = 'NY'
),
Tract_Totals AS (
    /* 3. Total population by census tract */
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM NY_BlockGroups
    GROUP BY "StateCountyTractID"
)

-- 4. Final result with division‑by‑zero protection
SELECT
    n."BlockGroupID",
    n."BlockGroupPopulation"                         AS "CensusValue",
    n."StateCountyTractID",
    t."TotalTractPopulation",
    n."BlockGroupPopulation" / NULLIF(t."TotalTractPopulation", 0) AS "PopulationRatio"
FROM NY_BlockGroups AS n
JOIN Tract_Totals  AS t
      ON n."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    n."StateCountyTractID",
    n."BlockGroupID";