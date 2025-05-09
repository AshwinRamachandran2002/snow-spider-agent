WITH temperature_data AS (
    SELECT date, AVG("temp") AS temperature
    FROM (
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2008"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2009"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        -- Repeat for GSOD2010 to GSOD2017
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2010"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
        UNION ALL
        SELECT TO_DATE(LPAD("year",4,'0') || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS date, "temp"
        FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
        WHERE ("stn" = '725030' AND "wban" = '94728') OR ("stn" = '744860' AND "wban" = '94789')
    ) temp
    GROUP BY date
),
complaint_data_raw AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) AS date,
        "complaint_type",
        COUNT(*) AS complaint_count
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE TO_TIMESTAMP_NTZ("created_date" / 1e6) BETWEEN '2008-01-01' AND '2017-12-31'
      AND (
          ("latitude" BETWEEN 40.63 AND 40.66 AND "longitude" BETWEEN -73.79 AND -73.76) -- JFK
          OR
          ("latitude" BETWEEN 40.75 AND 40.79 AND "longitude" BETWEEN -73.90 AND -73.85) -- LaGuardia
      )
    GROUP BY date, "complaint_type"
),
total_complaints_per_type AS (
    SELECT
        "complaint_type",
        SUM(complaint_count) AS total_complaint_count
    FROM complaint_data_raw
    GROUP BY "complaint_type"
    HAVING SUM(complaint_count) > 5000
),
complaint_data AS (
    SELECT
        cdr.date,
        cdr."complaint_type",
        cdr.complaint_count
    FROM complaint_data_raw cdr
    INNER JOIN total_complaints_per_type tct ON cdr."complaint_type" = tct."complaint_type"
),
total_daily_complaints AS (
    SELECT
        date,
        SUM(complaint_count) AS total_complaints
    FROM complaint_data
    GROUP BY date
),
daily_data AS (
    SELECT
        cd.date,
        cd."complaint_type",
        cd.complaint_count,
        tdc.total_complaints,
        (cd.complaint_count * 1.0) / tdc.total_complaints AS complaint_percentage,
        td.temperature
    FROM complaint_data cd
    JOIN total_daily_complaints tdc ON cd.date = tdc.date
    JOIN temperature_data td ON cd.date = td.date
)
SELECT
    dd."complaint_type" AS Complaint_Type,
    tc.total_complaint_count AS Total_Complaint_Count,
    COUNT(*) AS Total_Day_Count,
    ROUND(COVAR_POP(dd.temperature, dd.complaint_count) / (STDDEV_POP(dd.temperature) * STDDEV_POP(dd.complaint_count)), 4) AS Pearson_Correlation_Count,
    ROUND(COVAR_POP(dd.temperature, dd.complaint_percentage) / (STDDEV_POP(dd.temperature) * STDDEV_POP(dd.complaint_percentage)), 4) AS Pearson_Correlation_Percentage
FROM daily_data dd
JOIN total_complaints_per_type tc ON dd."complaint_type" = tc."complaint_type"
WHERE dd.temperature IS NOT NULL AND dd.complaint_count IS NOT NULL
GROUP BY dd."complaint_type", tc.total_complaint_count
HAVING ABS(ROUND(COVAR_POP(dd.temperature, dd.complaint_count) / (STDDEV_POP(dd.temperature) * STDDEV_POP(dd.complaint_count)), 4)) > 0.5
ORDER BY ABS(Pearson_Correlation_Count) DESC NULLS LAST;