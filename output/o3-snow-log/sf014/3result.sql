/*  New York ZIP with the greatest number of commuters whose one–way travel-time
    to work is more than 60 minutes (ACS-2021).
    “Over one hour” = MetricIDs B08303_011E  (60-89 min)  +
                       B08303_012E  (90 + min). */

/* --- ZIP-level portion ---------------------------------------------------- */
WITH ny_zips AS (   -- all NY ZIP codes present in the geography table
    SELECT DISTINCT g."ZipCode"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
    WHERE  g."PreferredStateAbbrev" = 'NY'
),
commute_60_89 AS (  -- 60-89-minute commuters per NY ZIP
    SELECT f."ZipCode",
           SUM(f."CensusValueByZip") AS "Commute_60_89"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
           ON f."ZipCode" = g."ZipCode"
    WHERE  g."PreferredStateAbbrev" = 'NY'
      AND  f."MetricID"            = 'B08303_011E'
    GROUP  BY f."ZipCode"
),
commute_90_plus AS ( -- 90-plus-minute commuters per NY ZIP
    SELECT f."ZipCode",
           SUM(f."CensusValueByZip") AS "Commute_90_plus"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip" f
    JOIN   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded" g
           ON f."ZipCode" = g."ZipCode"
    WHERE  g."PreferredStateAbbrev" = 'NY'
      AND  f."MetricID"            = 'B08303_012E'
    GROUP  BY f."ZipCode"
),
zip_totals AS (     -- combine the two commute buckets
    SELECT z."ZipCode",
           COALESCE(c60."Commute_60_89",0) + COALESCE(c90."Commute_90_plus",0) 
           AS "Total_Commuters_Over_60min"
    FROM   ny_zips                       z
    LEFT   JOIN commute_60_89            c60 USING ("ZipCode")
    LEFT   JOIN commute_90_plus          c90 USING ("ZipCode")
)

/* --- State-benchmark portion --------------------------------------------- */
, state_benchmark AS (
    SELECT SUM("StateBenchmarkValue") AS "StateBenchmark_Over_60min",
           MAX("TotalStatePopulation") AS "TotalStatePopulation"
    FROM   CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"
    WHERE  "StateAbbrev" = 'NY'
      AND  "MetricID"    IN ('B08303_011E','B08303_012E')
)

/* --- Final answer --------------------------------------------------------- */
SELECT 
       top_zip."ZipCode",
       ROUND(top_zip."Total_Commuters_Over_60min",4)    AS "Total_Commuters_Over_60min",
       ROUND(sb."StateBenchmark_Over_60min",4)          AS "State_Benchmark_Over_60min",
       sb."TotalStatePopulation"
FROM  (
        SELECT *
        FROM   zip_totals
        ORDER  BY "Total_Commuters_Over_60min" DESC NULLS LAST
        LIMIT  1           -- highest NY ZIP
      )                     top_zip
CROSS JOIN state_benchmark  sb;