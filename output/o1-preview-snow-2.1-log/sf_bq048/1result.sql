WITH common_complaints AS (
    SELECT "complaint_type"
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY "complaint_type"
    HAVING COUNT(*) > 3000
),
complaint_counts AS (
    SELECT
        DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) AS "date",
        "complaint_type",
        COUNT(*) AS "complaint_count"
    FROM "NEW_YORK_NOAA"."NEW_YORK"."_311_SERVICE_REQUESTS"
    WHERE "latitude" BETWEEN 40.6 AND 40.7
      AND "longitude" BETWEEN -73.8 AND -73.75
      AND DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)) BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY DATE(TO_TIMESTAMP_NTZ("created_date" / 1e6)), "complaint_type"
),
filtered_complaints AS (
    SELECT cc.*
    FROM complaint_counts cc
    JOIN common_complaints c ON cc."complaint_type" = c."complaint_type"
),
wind_speed_data AS (
    SELECT
        TO_DATE(CONCAT("year", '-', LPAD("mo",2,'0'), '-', LPAD("da",2,'0'))) AS "date",
        CAST("wdsp" AS FLOAT) AS "wind_speed"
    FROM (
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2018"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2019"
        UNION ALL
        SELECT "stn", "wban", "year", "mo", "da", "wdsp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2020"
    ) gsod
    WHERE gsod."stn" = '744860' AND gsod."wban" = '94789' AND gsod."wdsp" IS NOT NULL
),
complaints_with_wind AS (
    SELECT fc."complaint_type", fc."date", fc."complaint_count", ws."wind_speed"
    FROM filtered_complaints fc
    JOIN wind_speed_data ws ON fc."date" = ws."date"
),
complaint_correlations AS (
    SELECT
        c."complaint_type",
        CORR(c."complaint_count", c."wind_speed") AS "correlation_value"
    FROM complaints_with_wind c
    GROUP BY c."complaint_type"
),
ranking AS (
    SELECT
        cc."complaint_type",
        ROUND(cc."correlation_value", 4) AS "correlation_value",
        RANK() OVER (ORDER BY cc."correlation_value" DESC NULLS LAST) AS rank_desc,
        RANK() OVER (ORDER BY cc."correlation_value" ASC NULLS LAST) AS rank_asc
    FROM complaint_correlations cc
    WHERE cc."correlation_value" IS NOT NULL
)
SELECT
    "complaint_type", "correlation_value"
FROM ranking
WHERE rank_desc = 1 OR rank_asc = 1
ORDER BY "correlation_value" DESC NULLS LAST;