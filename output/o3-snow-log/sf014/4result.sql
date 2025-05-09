/*  New-York ZIP with the largest number of commuters whose one-way travel-time to work is
    60 minutes or longer (ACS-2021).  We combine the two ACS buckets
    – 60-89 minutes (B08303_012E) and 90 + minutes (B08303_013E).          */

WITH ny_zip_over1hr AS (   -- sum the two “≥60-min” buckets for every NY ZIP
    SELECT
        z."ZipCode",
        SUM(f."CensusValueByZip") AS "TotalCommutersOver1Hr"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"           z
           ON f."ZipCode" = z."ZipCode"
    WHERE  f."MetricID" IN ('B08303_012E', 'B08303_013E')      -- 60-89 & 90+ minutes
      AND  z."PreferredStateAbbrev" = 'NY'
    GROUP BY z."ZipCode"
),
top_zip AS (               -- pick the ZIP with the highest total
    SELECT
        "ZipCode",
        "TotalCommutersOver1Hr",
        ROW_NUMBER() OVER (ORDER BY "TotalCommutersOver1Hr" DESC NULLS LAST) AS rn
    FROM ny_zip_over1hr
)
SELECT 
    t."ZipCode",
    t."TotalCommutersOver1Hr",          -- commuters ≥60 min in that ZIP
    sb."StateBenchmarkValue"  AS "NY_StateBenchmark_Over1Hr",
    sb."TotalStatePopulation"
FROM   top_zip t
CROSS  JOIN (                -- state-level benchmark summed over the same two buckets
        SELECT 
            SUM("StateBenchmarkValue")        AS "StateBenchmarkValue",
            MAX("TotalStatePopulation")       AS "TotalStatePopulation"
        FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
        WHERE  "MetricID"    IN ('B08303_012E', 'B08303_013E')
          AND  "StateAbbrev" = 'NY'
) sb
WHERE  t.rn = 1;