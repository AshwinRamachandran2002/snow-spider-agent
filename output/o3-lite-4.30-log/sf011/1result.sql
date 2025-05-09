WITH ny_block_groups AS (
    SELECT
        g."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue"
    FROM "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021" f
    JOIN "CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE"."PUBLIC"."Dim_CensusGeography" g
      ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID" = 'B01003_001E'  -- Total population
      AND g."StateFIPS" = '36'          -- New York
),
tract_totals AS (
    SELECT
        "StateCountyTractID",
        SUM("CensusValue") AS "TotalTractPopulation"
    FROM ny_block_groups
    GROUP BY "StateCountyTractID"
    HAVING SUM("CensusValue") > 0       -- remove zero‑pop tracts
)

SELECT
    b."BlockGroupID"                        AS block_group_id,
    b."CensusValue"                         AS census_value,
    b."StateCountyTractID"                  AS state_county_tract_id,
    t."TotalTractPopulation"                AS total_tract_population,
    ROUND(b."CensusValue" / NULLIF(t."TotalTractPopulation", 0), 4)
                                            AS population_ratio
FROM ny_block_groups b
JOIN tract_totals t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY b."StateCountyTractID", b."BlockGroupID";