WITH ny_blockgroup_pop AS (
    /* Block‑group‑level total population (MetricID = B01003_001E) for NY */
    SELECT
        f."BlockGroupID",
        g."StateCountyTractID",
        CAST(f."CensusValue" AS FLOAT) AS "BlockGroupPopulation"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"  = 'B01003_001E'   -- Total population
      AND g."StateFIPS" = '36'            -- New York
),
tract_totals AS (
    /* Pre‑aggregate tract‑level totals to avoid division‑by‑zero issues */
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM ny_blockgroup_pop
    GROUP BY "StateCountyTractID"
)

SELECT
    n."BlockGroupID",
    n."StateCountyTractID",
    n."BlockGroupPopulation",
    t."TotalTractPopulation",
    ROUND(
        n."BlockGroupPopulation" / NULLIF(t."TotalTractPopulation", 0)
        , 4
    ) AS "BlockGroupToTractPopRatio"
FROM ny_blockgroup_pop n
JOIN tract_totals      t
  ON n."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    n."StateCountyTractID",
    n."BlockGroupID";