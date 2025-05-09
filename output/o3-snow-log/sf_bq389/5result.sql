WITH
-- Monthly average PM10
pm10 AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean")            AS "avg_pm10"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM10_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),

-- Monthly average PM2.5 (FRM)
pm25_frm AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean")            AS "avg_pm25_frm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_FRM_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),

-- Monthly average PM2.5 (non-FRM)
pm25_nonfrm AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean")            AS "avg_pm25_nonfrm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),

-- Monthly average VOC
voc AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean")            AS "avg_voc"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.VOC_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),

-- Monthly average SO2 (scaled ×10)
so2 AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean") * 10       AS "avg_so2_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.SO2_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),

-- Monthly average Lead (scaled ×100)
lead AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month",
        AVG("arithmetic_mean") * 100      AS "avg_lead_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.LEAD_DAILY_SUMMARY
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
)

-- Combine all pollutant metrics
SELECT
    pm10."month",
    pm10."avg_pm10",
    pm25_frm."avg_pm25_frm",
    pm25_nonfrm."avg_pm25_nonfrm",
    voc."avg_voc",
    so2."avg_so2_scaled",
    lead."avg_lead_scaled"
FROM pm10
LEFT JOIN pm25_frm    ON pm10."month" = pm25_frm."month"
LEFT JOIN pm25_nonfrm ON pm10."month" = pm25_nonfrm."month"
LEFT JOIN voc         ON pm10."month" = voc."month"
LEFT JOIN so2         ON pm10."month" = so2."month"
LEFT JOIN lead        ON pm10."month" = lead."month"
ORDER BY pm10."month";