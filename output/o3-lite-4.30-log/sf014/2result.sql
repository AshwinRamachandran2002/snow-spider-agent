WITH zip_long_commute AS (
    /* 60–89 minutes (B08303_012E) + 90 + minutes (B08303_013E) for NY ZIP codes */
    SELECT
        z."ZipCode",
        SUM(z."CensusValueByZip") AS total_commuters_over_1h
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"   z
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"              g
          ON g."ZipCode" = z."ZipCode"
    WHERE g."PreferredStateAbbrev" = 'NY'
      AND z."MetricID" IN ('B08303_012E','B08303_013E')
    GROUP BY z."ZipCode"
),
ny_benchmark AS (
    /* State benchmark and population for the same two long‑commute metrics */
    SELECT
        SUM("StateBenchmarkValue") AS state_benchmark_over_1h,
        MAX("TotalStatePopulation") AS state_population
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE "StateAbbrev" = 'NY'
      AND "MetricID" IN ('B08303_012E','B08303_013E')
)
SELECT
    z."ZipCode"                                            AS zip_code,
    ROUND(z.total_commuters_over_1h, 4)                    AS total_commuters_over_1h,
    ny.state_benchmark_over_1h                             AS state_benchmark_over_1h,
    ny.state_population                                    AS state_population
FROM zip_long_commute z
CROSS JOIN ny_benchmark ny
ORDER BY total_commuters_over_1h DESC NULLS LAST, z."ZipCode"
LIMIT 1;