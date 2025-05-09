WITH temp_data AS (
    SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2008"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2009"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2010"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9

    UNION ALL SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS date,
        CAST("temp" AS FLOAT) AS temp
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
    WHERE "stn" IN ('725030', '744860') AND "temp" <> 9999.9
),
temperature_daily AS (
    SELECT
        date,
        AVG(temp) AS avg_temp
    FROM temp_data
    GROUP BY date
),
complaints_data AS (
    SELECT
        DATE(CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_LTZ("created_date" / 1e6))) AS date,
        "complaint_type"
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        DATE(CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_LTZ("created_date" / 1e6))) >= '2008-01-01'
        AND DATE(CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_LTZ("created_date" / 1e6))) < '2018-01-01'
),
complaints_daily AS (
    SELECT
        date,
        "complaint_type",
        COUNT(*) AS daily_complaint_count
    FROM complaints_data
    GROUP BY date, "complaint_type"
),
daily_totals AS (
    SELECT
        date,
        SUM(daily_complaint_count) AS total_complaints_all_types
    FROM complaints_daily
    GROUP BY date
),
combined_data AS (
    SELECT
        cd.date,
        cd."complaint_type",
        cd.daily_complaint_count,
        cd.daily_complaint_count * 1.0 / dt.total_complaints_all_types AS daily_complaint_percentage,
        dt.total_complaints_all_types,
        td.avg_temp
    FROM complaints_daily cd
    INNER JOIN daily_totals dt ON cd.date = dt.date
    INNER JOIN temperature_daily td ON cd.date = td.date
),
complaint_totals AS (
    SELECT
        "complaint_type",
        SUM(daily_complaint_count) AS total_complaints_per_type
    FROM combined_data
    GROUP BY "complaint_type"
),
complaints_filtered AS (
    SELECT
        cd.*,
        ct.total_complaints_per_type
    FROM combined_data cd
    INNER JOIN complaint_totals ct ON cd."complaint_type" = ct."complaint_type"
    WHERE ct.total_complaints_per_type > 5000
),
calculations AS (
    SELECT
        cf."complaint_type",
        MAX(cf.total_complaints_per_type) AS total_complaints,
        COUNT(DISTINCT cf.date) AS total_days,
        CORR(cf.avg_temp, cf.daily_complaint_count) AS corr_count,
        CORR(cf.avg_temp, cf.daily_complaint_percentage) AS corr_percentage
    FROM complaints_filtered cf
    GROUP BY cf."complaint_type"
),
results AS (
    SELECT
        "complaint_type" AS "Complaint Type",
        total_complaints AS "Total Complaints",
        total_days AS "Total Days",
        ROUND(corr_count, 4) AS "Correlation Count",
        ROUND(corr_percentage, 4) AS "Correlation Percentage"
    FROM calculations
    WHERE ABS(corr_count) > 0.5 OR ABS(corr_percentage) > 0.5
)
SELECT
    "Complaint Type",
    "Total Complaints",
    "Total Days",
    "Correlation Count",
    "Correlation Percentage"
FROM results
ORDER BY "Complaint Type";