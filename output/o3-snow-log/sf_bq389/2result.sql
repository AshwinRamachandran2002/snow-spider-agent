/*  Monthly-average air-pollutant levels for California (2020)
    – PM10, PM2.5 (FRM & non-FRM), VOCs, SO₂ (×10), Lead (×100)              */

WITH pm AS (   /* combine PM10 + PM2.5 sources --------------------------------*/
    SELECT
        TO_CHAR("date_local",'YYYY-MM')                              AS "month",
        AVG(CASE WHEN "src" = 'PM10'   THEN "arithmetic_mean" END)   AS "pm10_avg_ug_m3",
        AVG(CASE WHEN "src" = 'FRM'    THEN "arithmetic_mean" END)   AS "pm25_frm_avg_ug_m3",
        AVG(CASE WHEN "src" = 'NONFRM' THEN "arithmetic_mean" END)   AS "pm25_nonfrm_avg_ug_m3"
    FROM (
            SELECT 'PM10'   AS "src","date_local","arithmetic_mean"
            FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM10_DAILY_SUMMARY"
            WHERE "state_code"='06'
              AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'

            UNION ALL
            SELECT 'FRM',   "date_local","arithmetic_mean"
            FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_FRM_DAILY_SUMMARY"
            WHERE "state_code"='06'
              AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'

            UNION ALL
            SELECT 'NONFRM',"date_local","arithmetic_mean"
            FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_NONFRM_DAILY_SUMMARY"
            WHERE "state_code"='06'
              AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
         ) src
    GROUP BY "month"
),
voc AS (       /* volatile organic compounds ----------------------------------*/
    SELECT
        TO_CHAR("date_local",'YYYY-MM') AS "month",
        AVG("arithmetic_mean")          AS "voc_avg_ppbc"
    FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."VOC_DAILY_SUMMARY"
    WHERE "state_code"='06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
so2 AS (       /* SO₂ – scale by 10 -------------------------------------------*/
    SELECT
        TO_CHAR("date_local",'YYYY-MM') AS "month",
        AVG("arithmetic_mean")*10       AS "so2_scaled_x10"
    FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."SO2_DAILY_SUMMARY"
    WHERE "state_code"='06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
pb  AS (       /* Lead – scale by 100 -----------------------------------------*/
    SELECT
        TO_CHAR("date_local",'YYYY-MM') AS "month",
        AVG("arithmetic_mean")*100      AS "lead_scaled_x100"
    FROM  EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."LEAD_DAILY_SUMMARY"
    WHERE "state_code"='06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
)
/* ----------------------- final join & display -------------------------------*/
SELECT
    pm."month",
    pm."pm10_avg_ug_m3",
    pm."pm25_frm_avg_ug_m3",
    pm."pm25_nonfrm_avg_ug_m3",
    voc."voc_avg_ppbc",
    so2."so2_scaled_x10",
    pb."lead_scaled_x100"
FROM   pm
LEFT  JOIN voc ON pm."month" = voc."month"
LEFT  JOIN so2 ON pm."month" = so2."month"
LEFT  JOIN pb  ON pm."month" = pb."month"
ORDER BY pm."month";