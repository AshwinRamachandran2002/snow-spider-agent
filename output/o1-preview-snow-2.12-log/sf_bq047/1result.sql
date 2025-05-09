WITH temp_data AS (
    SELECT "stn", "year", "mo", "da", "temp" FROM
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
    ) AS all_temps
    WHERE
        "stn" IN ('725030', '744860') -- LaGuardia and JFK station IDs
),
daily_temps AS (
    SELECT
        DATE_FROM_PARTS(CAST("year" AS INT), CAST("mo" AS INT), CAST("da" AS INT)) AS "date",
        AVG(CAST("temp" AS FLOAT)) AS "avg_temp"
    FROM temp_data
    GROUP BY "date"
),
daily_complaints_raw AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("created_date" / 1e6)) AS "date",
        "complaint_type"
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_DATE(TO_TIMESTAMP("created_date" / 1e6)) BETWEEN '2008-01-01' AND '2017-12-31'
        AND "latitude" IS NOT NULL AND "longitude" IS NOT NULL
        AND (
            ("latitude" BETWEEN 40.7269 AND 40.8269 AND "longitude" BETWEEN -73.9240 AND -73.8240) -- LaGuardia
            OR
            ("latitude" BETWEEN 40.5913 AND 40.6913 AND "longitude" BETWEEN -73.8281 AND -73.7281) -- JFK
        )
),
complaint_totals AS (
    SELECT
        "complaint_type",
        COUNT(*) AS "total_complaint_count"
    FROM daily_complaints_raw
    GROUP BY "complaint_type"
    HAVING COUNT(*) > 5000
),
daily_complaints AS (
    SELECT
        dcr."date",
        dcr."complaint_type",
        COUNT(*) AS "complaint_count"
    FROM daily_complaints_raw dcr
    JOIN complaint_totals ct ON dcr."complaint_type" = ct."complaint_type"
    GROUP BY dcr."date", dcr."complaint_type"
),
daily_totals AS (
    SELECT
        "date",
        SUM("complaint_count") AS "total_complaints"
    FROM daily_complaints
    GROUP BY "date"
),
daily_data AS (
    SELECT
        dc."date",
        dc."complaint_type",
        dc."complaint_count",
        dt."total_complaints",
        (dc."complaint_count" * 100.0 / dt."total_complaints") AS "complaint_percentage"
    FROM daily_complaints dc
    JOIN daily_totals dt ON dc."date" = dt."date"
),
joined_data AS (
    SELECT
        dd."complaint_type",
        dd."date",
        dd."complaint_count",
        dd."complaint_percentage",
        dt."avg_temp"
    FROM daily_data dd
    JOIN daily_temps dt ON dd."date" = dt."date"
)
SELECT
    jd."complaint_type",
    SUM(jd."complaint_count") AS "Total_Complaint_Count",
    COUNT(DISTINCT jd."date") AS "Total_Day_Count",
    ROUND(CORR(jd."complaint_count", jd."avg_temp"), 4) AS "Pearson_Correlation_Count",
    ROUND(CORR(jd."complaint_percentage", jd."avg_temp"), 4) AS "Pearson_Correlation_Percentage"
FROM
    joined_data jd
GROUP BY
    jd."complaint_type"
HAVING
    SUM(jd."complaint_count") > 5000
    AND (ABS(CORR(jd."complaint_count", jd."avg_temp")) > 0.5 
         OR ABS(CORR(jd."complaint_percentage", jd."avg_temp")) > 0.5)
ORDER BY
    "Total_Complaint_Count" DESC NULLS LAST;