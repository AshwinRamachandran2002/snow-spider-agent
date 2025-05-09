WITH
total_complaints_per_type AS (
    SELECT
        "complaint_type",
        COUNT("unique_key") AS "total_requests"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY
        "complaint_type"
    HAVING
        COUNT("unique_key") > 3000
),
complaint_counts AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000)) AS "date",
        "complaint_type",
        COUNT("unique_key") AS "daily_complaint_type_count"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
        AND "complaint_type" IN (SELECT "complaint_type" FROM total_complaints_per_type)
    GROUP BY
        "date",
        "complaint_type"
),
daily_total_complaints AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000)) AS "date",
        COUNT("unique_key") AS "daily_total_complaints"
    FROM
        "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE
        TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY
        "date"
),
complaint_proportions AS (
    SELECT
        cc."date",
        cc."complaint_type",
        cc."daily_complaint_type_count",
        dtc."daily_total_complaints",
        (cc."daily_complaint_type_count"::FLOAT / dtc."daily_total_complaints") AS "daily_complaint_proportion"
    FROM
        complaint_counts cc
    JOIN
        daily_total_complaints dtc
    ON
        cc."date" = dtc."date"
),
wind_speed AS (
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2018"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2019"
    WHERE "stn" = '744860'
    UNION ALL
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da")) AS "date",
        CAST("wdsp" AS FLOAT) AS "wdsp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2020"
    WHERE "stn" = '744860'
),
correlations AS (
    SELECT
        cp."complaint_type",
        CORR(cp."daily_complaint_proportion", ws."wdsp") AS "correlation_coefficient"
    FROM
        complaint_proportions cp
    JOIN
        wind_speed ws
    ON
        cp."date" = ws."date"
    GROUP BY
        cp."complaint_type"
),
positive_correlation AS (
    SELECT
        "complaint_type",
        ROUND("correlation_coefficient", 4) AS "Correlation_Coefficient"
    FROM
        correlations
    ORDER BY
        "correlation_coefficient" DESC NULLS LAST
    LIMIT 1
),
negative_correlation AS (
    SELECT
        "complaint_type",
        ROUND("correlation_coefficient", 4) AS "Correlation_Coefficient"
    FROM
        correlations
    ORDER BY
        "correlation_coefficient" ASC NULLS LAST
    LIMIT 1
)
SELECT
    "complaint_type" AS "Complaint_Type",
    "Correlation_Coefficient"
FROM
    positive_correlation
UNION ALL
SELECT
    "complaint_type" AS "Complaint_Type",
    "Correlation_Coefficient"
FROM
    negative_correlation;