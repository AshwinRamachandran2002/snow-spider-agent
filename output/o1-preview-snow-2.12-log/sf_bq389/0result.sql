WITH "months" AS (
    SELECT 1 AS "Month_num" UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5 UNION ALL
    SELECT 6 UNION ALL
    SELECT 7 UNION ALL
    SELECT 8 UNION ALL
    SELECT 9 UNION ALL
    SELECT 10 UNION ALL
    SELECT 11 UNION ALL
    SELECT 12
)
SELECT
    LPAD("months"."Month_num"::VARCHAR, 2, '0') AS "Month_num",
    TO_CHAR(TO_DATE("months"."Month_num"::VARCHAR, 'MM'), 'Mon') AS "Month",
    COALESCE("pm10"."PM10", 0) AS "PM10",
    COALESCE("pm25_frm"."PM2.5_FRM", 0) AS "PM2.5_FRM",
    COALESCE("pm25_non_frm"."PM2.5_non_FRM", 0) AS "PM2.5_non_FRM",
    COALESCE("voc"."VOC", 0) AS "VOC",
    COALESCE("so2"."SO2_scaled", 0) AS "SO2_scaled",
    COALESCE("lead"."Lead_scaled", 0) AS "Lead_scaled"
FROM
    "months"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean"), 4) AS "PM10"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM10_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "pm10" ON "months"."Month_num" = "pm10"."Month_num"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean"), 4) AS "PM2.5_FRM"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_FRM_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "pm25_frm" ON "months"."Month_num" = "pm25_frm"."Month_num"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean"), 4) AS "PM2.5_non_FRM"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "pm25_non_frm" ON "months"."Month_num" = "pm25_non_frm"."Month_num"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean"), 4) AS "VOC"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.VOC_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "voc" ON "months"."Month_num" = "voc"."Month_num"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean") * 10, 4) AS "SO2_scaled"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.SO2_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "so2" ON "months"."Month_num" = "so2"."Month_num"
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM "date_local") AS "Month_num",
            ROUND(AVG("arithmetic_mean") * 100, 4) AS "Lead_scaled"
        FROM
            EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.LEAD_DAILY_SUMMARY
        WHERE
            "state_name" = 'California'
            AND "date_local" >= '2020-01-01' AND "date_local" <= '2020-12-31'
        GROUP BY
            "Month_num"
    ) AS "lead" ON "months"."Month_num" = "lead"."Month_num"
ORDER BY
    "months"."Month_num";