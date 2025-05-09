WITH over1hr_metrics AS (          -- ACS “Travel‑time to work” metrics ≥60 minutes
    SELECT 'B08303_012E' AS "MetricID"   -- 60‑89 minutes
    UNION ALL
    SELECT 'B08303_013E'                 -- 90 minutes or more
),                                       
zip_over1hr AS (                         -- total commuters ≥60 minutes by NY ZIP
    SELECT  f."ZipCode",
            SUM(f."CensusValueByZip") AS "TotalCommutersOver1Hour"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  f
    JOIN   over1hr_metrics m
           ON f."MetricID" = m."MetricID"
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
           ON f."ZipCode" = g."ZipCode"
    WHERE  g."PreferredStateAbbrev" = 'NY'                      -- New York only
    GROUP  BY f."ZipCode"
),                                       
state_over1hr AS (                       -- NY state benchmark, commuters ≥60 minutes
    SELECT  SUM(s."StateBenchmarkValue") AS "StateBenchmarkOver1Hour",
            MAX(s."TotalStatePopulation") AS "StatePopulation"
    FROM    CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021" s
    JOIN    over1hr_metrics m
            ON s."MetricID" = m."MetricID"
    WHERE   s."StateAbbrev" = 'NY'
),                                       
ranked_zip AS (                          -- rank ZIPs by commuters ≥60 minutes
    SELECT  z.*,
            ROW_NUMBER() OVER (ORDER BY z."TotalCommutersOver1Hour" DESC NULLS LAST,
                                         z."ZipCode") AS rn
    FROM    zip_over1hr z
)
SELECT  r."ZipCode",
        r."TotalCommutersOver1Hour",
        s."StateBenchmarkOver1Hour",
        s."StatePopulation"
FROM    ranked_zip r
CROSS JOIN state_over1hr s
WHERE   r.rn = 1;                        -- highest NY ZIP for ≥60‑minute commuters