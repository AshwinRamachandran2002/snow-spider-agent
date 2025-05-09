/*  New York ZIP code with the greatest number of ≥ 60-minute commuters (ACS 2021)  */
WITH zip_level AS (   -- sum the 60-89 min and 90+ min buckets for each NY ZIP
    SELECT
        z."ZipCode",
        SUM(z."CensusValueByZip") AS "Total_Commuters_60plus"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  z
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"             g
          ON z."ZipCode" = g."ZipCode"
    WHERE z."MetricID" IN ('B08303_012E',   -- 60-89 minutes
                           'B08303_013E')   -- 90 minutes or more
      AND g."PreferredStateAbbrev" = 'NY'
    GROUP BY z."ZipCode"
),
state_level AS (      -- statewide total for the two same buckets
    SELECT
        SUM("StateBenchmarkValue") AS "NY_State_Commuters_60plus",
        MAX("TotalStatePopulation") AS "TotalStatePopulation"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E','B08303_013E')
),
ranked_zip AS (       -- rank ZIPs by commuter count
    SELECT
        z.*,
        ROW_NUMBER() OVER (ORDER BY z."Total_Commuters_60plus" DESC NULLS LAST) AS rn
    FROM zip_level z
)
SELECT
    r."ZipCode",
    r."Total_Commuters_60plus",
    s."NY_State_Commuters_60plus",
    s."TotalStatePopulation"
FROM ranked_zip r
CROSS JOIN state_level s
WHERE r.rn = 1;       -- highest-value ZIP only