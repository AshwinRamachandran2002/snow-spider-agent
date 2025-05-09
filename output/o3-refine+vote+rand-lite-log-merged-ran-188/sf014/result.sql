WITH over_hour_metrics AS (   /* Metrics that represent commuters whose travel time to work is 60 minutes or more */
    SELECT "MetricID"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Dim_CensusMetrics"
    WHERE "MetricTableID" = 'B08303'
      AND (
            "Descriptor1" ILIKE '%60%' OR "Descriptor2" ILIKE '%60%' OR "Descriptor3" ILIKE '%60%' OR
            "MetricTableDesc" ILIKE '%60%' OR
            "Descriptor1" ILIKE '%90%' OR "Descriptor2" ILIKE '%90%' OR "Descriptor3" ILIKE '%90%'
          )
), 

zip_over_hour_commuters AS (   /* Total 60+‑minute commuters for every ZIP */
    SELECT fv."ZipCode",
           SUM(fv."CensusValueByZip") AS "TotalOverHourCommuters"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021_ByZip"  fv
    JOIN over_hour_metrics m
      ON fv."MetricID" = m."MetricID"
    GROUP BY fv."ZipCode"
),

ny_zip_over_hour AS (          /* Keep only New York State ZIP codes */
    SELECT zc."ZipCode",
           zc."TotalOverHourCommuters"
    FROM zip_over_hour_commuters          zc
    JOIN CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."LU_GeographyExpanded"  lu
      ON zc."ZipCode" = lu."ZipCode"
    WHERE lu."PreferredStateAbbrev" = 'NY'
),

state_totals AS (              /* 60+‑minute commuters & population for New York State */
    SELECT SUM(fs."StateBenchmarkValue")  AS "StateBenchmarkOverHour",
           MAX(fs."TotalStatePopulation") AS "TotalStatePopulation"
    FROM CENSUS_GALAXY__AIML_MODEL_DATA_ENRICHMENT_SAMPLE.PUBLIC."Fact_StateBenchmark_ACS2021"   fs
    JOIN over_hour_metrics m
      ON fs."MetricID" = m."MetricID"
    WHERE fs."StateAbbrev" = 'NY'
)

SELECT  nz."ZipCode",
        nz."TotalOverHourCommuters",
        st."StateBenchmarkOverHour",
        st."TotalStatePopulation"
FROM    ny_zip_over_hour  nz
CROSS JOIN state_totals   st
ORDER BY nz."TotalOverHourCommuters" DESC NULLS LAST,
         nz."ZipCode"                 ASC
LIMIT 1;