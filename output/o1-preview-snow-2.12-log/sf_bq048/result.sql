WITH complaint_types AS (
  SELECT "complaint_type"
  FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
  WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY "complaint_type"
  HAVING COUNT(*) > 3000
),
daily_total_complaints AS (
  SELECT
    TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) AS "date",
    COUNT(*) AS total_complaints
  FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
  WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6))
),
daily_complaints_per_type AS (
  SELECT
    TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) AS "date",
    "complaint_type",
    COUNT(*) AS complaints_of_type
  FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
  WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) BETWEEN '2011-01-01' AND '2020-12-31'
    AND "complaint_type" IN (SELECT "complaint_type" FROM complaint_types)
  GROUP BY TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)), "complaint_type"
),
complaint_proportions AS (
  SELECT
    cpt."date",
    cpt."complaint_type",
    cpt.complaints_of_type,
    dtc.total_complaints,
    cpt.complaints_of_type * 1.0 / dtc.total_complaints AS complaint_proportion
  FROM daily_complaints_per_type cpt
  JOIN daily_total_complaints dtc ON cpt."date" = dtc."date"
),
weather_data AS (
  SELECT
    DATE_FROM_PARTS(TO_NUMBER("year"), TO_NUMBER("mo"), TO_NUMBER("da")) AS "date",
    NULLIF("wdsp", '999.9') AS "wdsp_raw"
  FROM (
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2011"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2012"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2013"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2014"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2015"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2016"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2017"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2018"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2019"
    UNION ALL
    SELECT "year", "mo", "da", "wdsp", "stn" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2020"
  ) gsod
  WHERE "stn" = '744860'
),
weather_data_clean AS (
  SELECT
    "date",
    TRY_TO_DOUBLE("wdsp_raw") AS "daily_wind_speed"
  FROM weather_data
  WHERE "wdsp_raw" IS NOT NULL
),
combined_data AS (
  SELECT
    cp."date",
    cp."complaint_type",
    cp.complaint_proportion,
    wd."daily_wind_speed"
  FROM complaint_proportions cp
  JOIN weather_data_clean wd ON cp."date" = wd."date"
  WHERE wd."daily_wind_speed" IS NOT NULL
),
correlations AS (
  SELECT
    "complaint_type",
    CORR(complaint_proportion, "daily_wind_speed") AS correlation_coefficient
  FROM combined_data
  GROUP BY "complaint_type"
),
positive_corr AS (
  SELECT
    "complaint_type",
    correlation_coefficient,
    ROW_NUMBER() OVER (ORDER BY correlation_coefficient DESC NULLS LAST) AS rn
  FROM correlations
),
negative_corr AS (
  SELECT
    "complaint_type",
    correlation_coefficient,
    ROW_NUMBER() OVER (ORDER BY correlation_coefficient ASC NULLS LAST) AS rn
  FROM correlations
)
SELECT CSV_Row FROM (
  SELECT 1 AS sort_order, 'Complaint_Type,Correlation_Coefficient' AS CSV_Row
  UNION ALL
  SELECT 2 AS sort_order, CONCAT(positive_corr."complaint_type", ',', TO_CHAR(ROUND(positive_corr.correlation_coefficient, 4)))
  FROM positive_corr
  WHERE rn = 1
  UNION ALL
  SELECT 3 AS sort_order, CONCAT(negative_corr."complaint_type", ',', TO_CHAR(ROUND(negative_corr.correlation_coefficient, 4)))
  FROM negative_corr
  WHERE rn = 1
) ORDER BY sort_order;