WITH ny_zip_totals AS (
    SELECT 
        f."ZipCode",
        SUM(f."CensusValueByZip") AS total_commuters_over_1h
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_CensusValues_ACS2021_ByZip" f
    JOIN "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."LU_GeographyExpanded" g
          ON f."ZipCode" = g."ZipCode"
    WHERE f."MetricID" IN ('B08303_012E', 'B08303_013E')      -- 60‑89 min & 90+ min commuters
      AND g."PreferredStateAbbrev" = 'NY'
    GROUP BY f."ZipCode"
), top_zip AS (
    SELECT 
        "ZipCode",
        total_commuters_over_1h
    FROM ny_zip_totals
    ORDER BY total_commuters_over_1h DESC NULLS LAST
    LIMIT 1
), state_totals AS (
    SELECT
        SUM(sb."StateBenchmarkValue") AS state_benchmark_over_1h,
        MAX(sb."TotalStatePopulation") AS state_population
    FROM "CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE"."PUBLIC"."Fact_StateBenchmark_ACS2021" sb
    WHERE sb."StateAbbrev" = 'NY'
      AND sb."MetricID" IN ('B08303_012E', 'B08303_013E')
)
SELECT
    tz."ZipCode"                                                      AS zip_code,
    CAST(ROUND(tz.total_commuters_over_1h, 4) AS NUMBER(38,4))        AS total_commuters_over_1h,
    CAST(ROUND(st.state_benchmark_over_1h, 4) AS NUMBER(38,4))        AS state_benchmark_over_1h,
    st.state_population                                               AS state_population
FROM top_zip tz
CROSS JOIN state_totals st;