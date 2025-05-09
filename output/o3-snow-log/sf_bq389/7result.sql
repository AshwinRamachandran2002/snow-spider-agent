WITH
-- Monthly-average PM10
pm10 AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean")           AS "pm10"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM10_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
),
-- Monthly-average PM2.5 (FRM)
pm25_frm AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean")            AS "pm25_frm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_FRM_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
),
-- Monthly-average PM2.5 (non-FRM)
pm25_nonfrm AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean")            AS "pm25_nonfrm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
),
-- Monthly-average VOCs
voc AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean")            AS "voc"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.VOC_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
),
-- Monthly-average SO2 (scaled ×10)
so2 AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean") * 10       AS "so2_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.SO2_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
),
-- Monthly-average Lead (scaled ×100)
lead AS (
    SELECT
        DATE_TRUNC('month', "date_local") AS "month_2020",
        AVG("arithmetic_mean") * 100      AS "lead_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.LEAD_DAILY_SUMMARY
    WHERE "state_name" = 'California'
      AND YEAR("date_local") = 2020
    GROUP BY 1
)

SELECT
    pm10."month_2020",
    pm10."pm10",
    pm25_frm."pm25_frm",
    pm25_nonfrm."pm25_nonfrm",
    voc."voc",
    so2."so2_scaled",
    lead."lead_scaled"
FROM pm10
LEFT JOIN pm25_frm    ON pm10."month_2020" = pm25_frm."month_2020"
LEFT JOIN pm25_nonfrm ON pm10."month_2020" = pm25_nonfrm."month_2020"
LEFT JOIN voc         ON pm10."month_2020" = voc."month_2020"
LEFT JOIN so2         ON pm10."month_2020" = so2."month_2020"
LEFT JOIN lead        ON pm10."month_2020" = lead."month_2020"
ORDER BY pm10."month_2020";