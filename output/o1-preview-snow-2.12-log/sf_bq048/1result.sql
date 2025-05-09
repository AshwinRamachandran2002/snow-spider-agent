WITH daily_totals AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000)) AS created_date,
        COUNT(*) AS total_complaints
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY 1
),
daily_type_counts AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000)) AS created_date,
        "complaint_type",
        COUNT(*) AS type_complaints
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY 1, 2
),
daily_proportions AS (
    SELECT
        dt.created_date,
        dt."complaint_type",
        dt.type_complaints / total.total_complaints::FLOAT AS proportion
    FROM daily_type_counts dt
    JOIN daily_totals total ON dt.created_date = total.created_date
),
complaint_type_totals AS (
    SELECT
        "complaint_type",
        COUNT(*) AS total_requests
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE TO_TIMESTAMP("created_date" / 1000000) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY 1
    HAVING COUNT(*) > 3000
),
wind_data AS (
    SELECT
        TO_DATE(CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0')), 'YYYY-MM-DD') AS date,
        "wdsp"
    FROM (
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2018" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2019" WHERE "stn" = '744860'
        UNION ALL
        SELECT "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2020" WHERE "stn" = '744860'
    ) AS wd
),
data_combined AS (
    SELECT
        dp."complaint_type",
        dp.created_date,
        dp.proportion,
        wd."wdsp" AS wind_speed
    FROM daily_proportions dp
    JOIN wind_data wd ON dp.created_date = wd.date
    WHERE dp."complaint_type" IN (SELECT "complaint_type" FROM complaint_type_totals)
),
correlations AS (
    SELECT
        "complaint_type",
        CORR(proportion, wind_speed) AS corr_coef
    FROM data_combined
    GROUP BY 1
),
max_corr AS (
    SELECT "complaint_type", corr_coef
    FROM correlations
    ORDER BY corr_coef DESC NULLS LAST
    LIMIT 1
),
min_corr AS (
    SELECT "complaint_type", corr_coef
    FROM correlations
    ORDER BY corr_coef ASC NULLS LAST
    LIMIT 1
)
SELECT 'Complaint_Type' AS Complaint_Type, 'Correlation_Coefficient' AS Correlation_Coefficient
UNION ALL
SELECT "complaint_type", TO_VARCHAR(ROUND(corr_coef, 4))
FROM max_corr
UNION ALL
SELECT "complaint_type", TO_VARCHAR(ROUND(corr_coef, 4))
FROM min_corr;