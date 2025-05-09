WITH months AS (
    SELECT "Month_num",
           TO_CHAR(DATE_FROM_PARTS(2020, "Month_num", 1), 'Mon') AS "Month"
    FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS T("Month_num")
),
pm10 AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") AS "PM10"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM10_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
pm25_frm AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") AS "PM2.5_FRM"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM25_FRM_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
pm25_non_frm AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") AS "PM2.5_non_FRM"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM25_NONFRM_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
voc AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") AS "VOC"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."VOC_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
so2 AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") * 10 AS "SO2_scaled"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."SO2_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
lead AS (
    SELECT EXTRACT(MONTH FROM "date_local") AS "Month_num",
           AVG("arithmetic_mean") * 100 AS "Lead_scaled"
    FROM "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."LEAD_DAILY_SUMMARY"
    WHERE "state_name" = 'California' AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
)
SELECT 
    LPAD(TO_VARCHAR(months."Month_num"), 2, '0') AS "Month_num",
    months."Month",
    ROUND(pm10."PM10", 4) AS "PM10",
    ROUND(pm25_frm."PM2.5_FRM", 4) AS "PM2.5_FRM",
    ROUND(pm25_non_frm."PM2.5_non_FRM", 4) AS "PM2.5_non_FRM",
    ROUND(voc."VOC", 4) AS "VOC",
    ROUND(so2."SO2_scaled", 4) AS "SO2_scaled",
    ROUND(lead."Lead_scaled", 4) AS "Lead_scaled"
FROM months
LEFT JOIN pm10 ON months."Month_num" = pm10."Month_num"
LEFT JOIN pm25_frm ON months."Month_num" = pm25_frm."Month_num"
LEFT JOIN pm25_non_frm ON months."Month_num" = pm25_non_frm."Month_num"
LEFT JOIN voc ON months."Month_num" = voc."Month_num"
LEFT JOIN so2 ON months."Month_num" = so2."Month_num"
LEFT JOIN lead ON months."Month_num" = lead."Month_num"
ORDER BY months."Month_num";