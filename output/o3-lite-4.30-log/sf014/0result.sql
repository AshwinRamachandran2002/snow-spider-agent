SELECT
        zc."ZipCode"                                  AS zip_code,
        CAST(zc.total_commuters_over_1h AS NUMBER(38,4))  AS total_commuters_over_1h,
        CAST(sb.state_benchmark_over_1h AS NUMBER(38,4))  AS state_benchmark_over_1h,
        sb.state_population                           AS state_population
FROM   (
           /* commuters with travel time ≥ 60 minutes by ZIP */
           SELECT
                  f."ZipCode",
                  SUM(f."CensusValueByZip") AS total_commuters_over_1h
           FROM  "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip"  f
           JOIN  "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded"            g
                 ON f."ZipCode" = g."ZipCode"
           WHERE g."PreferredStateAbbrev" = 'NY'
             AND f."MetricID" IN ('B08303_012E',                -- 60‑89 minutes
                                  'B08303_013E')                -- 90+ minutes
           GROUP BY f."ZipCode"
       ) zc
CROSS JOIN
       (
           /* statewide benchmark and population for ≥ 60‑minute commuters */
           SELECT
                  SUM("StateBenchmarkValue") AS state_benchmark_over_1h,
                  MAX("TotalStatePopulation") AS state_population
           FROM  "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021"
           WHERE "StateAbbrev" = 'NY'
             AND "MetricID" IN ('B08303_012E',
                                'B08303_013E')
       ) sb
ORDER BY zc.total_commuters_over_1h DESC NULLS LAST
LIMIT 1;