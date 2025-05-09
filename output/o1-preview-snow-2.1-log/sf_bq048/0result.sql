WITH complaints AS (
   SELECT 
      TO_DATE(TO_TIMESTAMP("created_date" / 1e6)) AS date,
      "complaint_type"
   FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
   WHERE "borough" = 'QUEENS'
     AND TO_TIMESTAMP("created_date" / 1e6) BETWEEN '2011-01-01' AND '2020-12-31'
),

complaint_counts AS (
   SELECT 
      date, 
      "complaint_type", 
      COUNT(*) AS complaint_count
   FROM complaints
   GROUP BY date, "complaint_type"
),

complaint_types AS (
   SELECT 
      "complaint_type",
      COUNT(*) AS total_complaints
   FROM complaints
   GROUP BY "complaint_type"
   HAVING COUNT(*) > 3000
),

filtered_complaint_counts AS (
   SELECT 
      cc.date,
      cc."complaint_type",
      cc.complaint_count
   FROM complaint_counts cc
   JOIN complaint_types ct ON cc."complaint_type" = ct."complaint_type"
),

wind_speed_data AS (
   SELECT
      TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) AS date,
      CAST("wdsp" AS FLOAT) AS wind_speed
   FROM (
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 WHERE "stn" = '744860'
      UNION ALL
      SELECT "year", "mo", "da", "wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020 WHERE "stn" = '744860'
   )
),

daily_wind_speed AS (
   SELECT 
      date, 
      AVG(wind_speed) AS avg_wind_speed
   FROM wind_speed_data
   GROUP BY date
),

complaints_and_wind_speed AS (
   SELECT 
      fc.date,
      fc."complaint_type",
      fc.complaint_count,
      dws.avg_wind_speed
   FROM filtered_complaint_counts fc
   JOIN daily_wind_speed dws ON fc.date = dws.date
),

correlations AS (
   SELECT 
      "complaint_type",
      CORR(complaint_count, avg_wind_speed) AS correlation_value
   FROM complaints_and_wind_speed
   GROUP BY "complaint_type"
),

ranked_correlations AS (
   SELECT
      "complaint_type" AS "Complaint_Type",
      ROUND(correlation_value, 4) AS "Correlation_Value",
      ROW_NUMBER() OVER (ORDER BY correlation_value DESC NULLS LAST) AS rn_desc,
      ROW_NUMBER() OVER (ORDER BY correlation_value ASC NULLS LAST) AS rn_asc
   FROM correlations
)

SELECT 
   "Complaint_Type",
   "Correlation_Value"
FROM ranked_correlations
WHERE rn_desc = 1 OR rn_asc = 1;