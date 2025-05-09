WITH dates AS (
    SELECT
        DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, TO_DATE('2008-01-01')) AS "date"
    FROM
        TABLE(GENERATOR(ROWCOUNT => 3653))
),
total_complaints_per_type AS (
    SELECT
        "complaint_type",
        COUNT(*) AS "total_complaint_count"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1e6)) BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY
        "complaint_type"
    HAVING
        COUNT(*) >= 5000
),
complaints_daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1e6)) AS "complaint_date",
        "complaint_type",
        COUNT(*) AS "daily_count"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1e6)) BETWEEN '2008-01-01' AND '2017-12-31'
        AND "complaint_type" IN (SELECT "complaint_type" FROM total_complaints_per_type)
    GROUP BY
        "complaint_date", "complaint_type"
),
total_daily_complaints AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1e6)) AS "complaint_date",
        COUNT(*) AS "total_daily_complaints"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1e6)) BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY
        "complaint_date"
),
temperature_data AS (
    SELECT
        TO_DATE(CONCAT(g."year", '-', LPAD(g."mo",2,'0'), '-', LPAD(g."da",2,'0')), 'YYYY-MM-DD') AS "observation_date",
        AVG(g."temp") AS "avg_temp"
    FROM
        (
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2008"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2009"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2010"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
            UNION ALL
            SELECT * FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
        ) AS g
    WHERE
        (g."stn"='725030' AND g."wban"='14732') OR (g."stn"='744860' AND g."wban"='94789')
        AND TO_DATE(CONCAT(g."year", '-', LPAD(g."mo",2,'0'), '-', LPAD(g."da",2,'0')), 'YYYY-MM-DD') BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY
        "observation_date"
),
full_data AS (
    SELECT
        d."date" AS "complaint_date",
        t."avg_temp",
        c."complaint_type",
        COALESCE(c."daily_count", 0) AS "daily_count",
        COALESCE(tdc."total_daily_complaints", 0) AS "total_daily_complaints",
        CASE WHEN tdc."total_daily_complaints" > 0 THEN COALESCE(c."daily_count", 0)/tdc."total_daily_complaints" ELSE 0 END AS "daily_percentage"
    FROM
        dates d
    LEFT JOIN
        temperature_data t
    ON
        d."date" = t."observation_date"
    LEFT JOIN
        total_daily_complaints tdc
    ON
        d."date" = tdc."complaint_date"
    LEFT JOIN
        complaints_daily c
    ON
        d."date" = c."complaint_date"
)
SELECT
    "complaint_type",
    SUM("daily_count") AS "Total_Complaint_Count",
    COUNT(*) AS "Total_Day_Count",
    ROUND(CORR("avg_temp", "daily_count"),4) AS "Pearson_Correlation_Count",
    ROUND(CORR("avg_temp", "daily_percentage"),4) AS "Pearson_Correlation_Percentage"
FROM
    full_data
WHERE
    "avg_temp" IS NOT NULL
GROUP BY
    "complaint_type"
HAVING
    ABS(CORR("avg_temp", "daily_count")) > 0.5 OR ABS(CORR("avg_temp", "daily_percentage")) > 0.5
ORDER BY
    "complaint_type";