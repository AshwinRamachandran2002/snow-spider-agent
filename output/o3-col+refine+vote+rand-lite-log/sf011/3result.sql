/*  Population share of every Block Group within its Census Tract – NY, ACS-2021  */
WITH bg_pop AS (      -- block-group population
    SELECT  
        f."BlockGroupID",
        g."StateCountyTractID",
        f."CensusValue"  AS "BlockGroupPop"
    FROM  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021"  f
    JOIN  CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography"       g
          ON f."BlockGroupID" = g."BlockGroupID"
    WHERE f."MetricID"   = 'B01003_001E'       -- Total population
      AND g."StateAbbrev" = 'NY'               -- New York only
), 
tract_totals AS (      -- total population per tract
    SELECT  
        "StateCountyTractID",
        SUM("BlockGroupPop") AS "TotalTractPopulation"
    FROM bg_pop
    GROUP BY "StateCountyTractID"
)
SELECT  
    b."BlockGroupID",
    b."StateCountyTractID",
    b."BlockGroupPop"                    AS "CensusValue",
    t."TotalTractPopulation",
    ROUND( b."BlockGroupPop" / NULLIF(t."TotalTractPopulation",0), 6 )  
        AS "BlockGroupPopRatio"
FROM        bg_pop      b
JOIN        tract_totals t
       ON   b."StateCountyTractID" = t."StateCountyTractID"
ORDER BY    b."StateCountyTractID",
            "BlockGroupPopRatio" DESC NULLS LAST;