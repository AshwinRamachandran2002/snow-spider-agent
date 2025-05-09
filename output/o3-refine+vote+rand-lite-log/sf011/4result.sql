/*  Population distribution of each Block Group within its parent Census Tract – New York State (ACS 2021)
    (handles possible zero‑population tracts to avoid division‑by‑zero) */
WITH BlockGroup_Pop AS (
    SELECT
        bg."BlockGroupID",
        fc."CensusValue"                  AS "BlockGroupPopulation",
        bg."StateCountyTractID"
    FROM CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  fc
    JOIN CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"        bg
          ON fc."BlockGroupID" = bg."BlockGroupID"
    WHERE fc."MetricID"    = 'B01003_001E'     -- Total population
      AND bg."StateAbbrev" = 'NY'              -- New York only
), 
Tract_Pop AS (
    SELECT
        "StateCountyTractID",
        SUM("BlockGroupPopulation") AS "TotalTractPopulation"
    FROM BlockGroup_Pop
    GROUP BY "StateCountyTractID"
)
SELECT
    b."BlockGroupID",
    b."BlockGroupPopulation"                         AS "CensusValue",
    b."StateCountyTractID",
    t."TotalTractPopulation",
    b."BlockGroupPopulation" / NULLIF(t."TotalTractPopulation", 0) 
        AS "PopulationRatioBGtoTract"
FROM BlockGroup_Pop b
JOIN Tract_Pop      t
  ON b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY
    b."StateCountyTractID",
    b."BlockGroupID";