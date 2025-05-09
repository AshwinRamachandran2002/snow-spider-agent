/* -------------------------------------------------------------
   Monthly average levels (California – 2020)
   PM10 , PM2.5-FRM , PM2.5-Non-FRM , VOC ,
   SO2 (×10) , Lead (×100)
--------------------------------------------------------------*/
WITH
pm10 AS (          -- PM10 Daily Summary
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")           AS "pm10_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM10_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
pm25_frm AS (      -- PM2.5 (FRM) Daily Summary
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")           AS "pm25_frm_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_FRM_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
pm25_nonfrm AS (   -- PM2.5 (Non-FRM) Daily Summary
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")           AS "pm25_nonfrm_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_NONFRM_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
voc AS (           -- Volatile Organic Compounds Daily Summary
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")           AS "voc_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."VOC_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
so2 AS (           -- SO2 Daily Summary  (scaled ×10)
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")*10        AS "so2_scaled_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."SO2_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
lead AS (          -- Lead Daily Summary  (scaled ×100)
    SELECT
        TO_CHAR("date_local",'YYYY-MM')  AS "month",
        AVG("arithmetic_mean")*100       AS "lead_scaled_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."LEAD_DAILY_SUMMARY"
    WHERE "state_code" = '06'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY "month"
),
all_months AS (    -- union of every month appearing in any CTE
    SELECT "month" FROM pm10
    UNION
    SELECT "month" FROM pm25_frm
    UNION
    SELECT "month" FROM pm25_nonfrm
    UNION
    SELECT "month" FROM voc
    UNION
    SELECT "month" FROM so2
    UNION
    SELECT "month" FROM lead
)

SELECT
    am."month",
    pm10."pm10_avg",
    pm25_frm."pm25_frm_avg",
    pm25_nonfrm."pm25_nonfrm_avg",
    voc."voc_avg",
    so2."so2_scaled_avg",
    lead."lead_scaled_avg"
FROM all_months  am
LEFT JOIN pm10         ON am."month" = pm10."month"
LEFT JOIN pm25_frm     ON am."month" = pm25_frm."month"
LEFT JOIN pm25_nonfrm  ON am."month" = pm25_nonfrm."month"
LEFT JOIN voc          ON am."month" = voc."month"
LEFT JOIN so2          ON am."month" = so2."month"
LEFT JOIN lead         ON am."month" = lead."month"
ORDER BY am."month";