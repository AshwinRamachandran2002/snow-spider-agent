WITH temp_data AS (
    SELECT
        TO_DATE(CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0'))) AS "date",
        AVG("temp") AS "avg_temp"
    FROM (
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2008"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2009"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2010"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2011"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2012"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2013"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2014"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2015"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2016"
        UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2017"
    ) gsod_data
    WHERE
        "stn" IN ('725030', '744860') AND "temp" <> 9999.9
    GROUP BY "date"
),
complaint_data AS (
    SELECT
        DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000)) AS "date",
        "complaint_type",
        COUNT(*) AS "daily_count"
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE
        DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000)) BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY "date", "complaint_type"
),
total_daily_complaints AS (
    SELECT
        "date",
        SUM("daily_count") AS "total_daily_complaints"
    FROM complaint_data
    GROUP BY "date"
),
complaints_with_temp AS (
    SELECT
        c."date",
        c."complaint_type",
        c."daily_count",
        tdc."total_daily_complaints",
        (c."daily_count"::float / tdc."total_daily_complaints") AS "daily_percentage",
        td."avg_temp"
    FROM complaint_data c
    JOIN total_daily_complaints tdc ON c."date" = tdc."date"
    JOIN temp_data td ON c."date" = td."date"
)
SELECT
    "complaint_type",
    SUM("daily_count") AS "total_complaints",
    COUNT(DISTINCT "date") AS "total_days",
    ROUND(CORR("avg_temp", "daily_count"), 4) AS "corr_count",
    ROUND(CORR("avg_temp", "daily_percentage"), 4) AS "corr_percentage"
FROM complaints_with_temp
GROUP BY "complaint_type"
HAVING
    SUM("daily_count") > 5000
    AND (
        ABS(CORR("avg_temp", "daily_count")) > 0.5
        OR ABS(CORR("avg_temp", "daily_percentage")) > 0.5
    )
ORDER BY "complaint_type";