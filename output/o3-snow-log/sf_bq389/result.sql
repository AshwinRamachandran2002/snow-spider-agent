WITH pm10 AS (   -- PM10 daily  monthly average
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean")                   AS pm10_avg
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM10_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
),

pm25_frm AS (    -- PM2.5 FRM daily  monthly average
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean")                   AS pm25_frm_avg
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_FRM_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
),

pm25_nonfrm AS ( -- PM2.5 non-FRM daily  monthly average
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean")                   AS pm25_nonfrm_avg
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
),

voc AS (         -- VOC daily  monthly average  (ppb-C)
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean")                   AS voc_avg_ppbC
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.VOC_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
),

so2 AS (         -- SO₂ daily  monthly average   (scaled ×10)
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean") * 10              AS so2_scaled_by_10
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.SO2_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
),

lead AS (        -- Lead daily  monthly average (scaled ×100)
    SELECT
        DATE_TRUNC('month', "date_local")        AS mon ,
        AVG("arithmetic_mean") * 100             AS lead_scaled_by_100
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.LEAD_DAILY_SUMMARY
    WHERE  "state_code" = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY mon
)

SELECT
    COALESCE(pm10.mon , pm25_frm.mon , pm25_nonfrm.mon ,
             voc.mon  , so2.mon     , lead.mon)           AS "month",
    pm10.pm10_avg,
    pm25_frm.pm25_frm_avg,
    pm25_nonfrm.pm25_nonfrm_avg,
    voc.voc_avg_ppbC,
    so2.so2_scaled_by_10,
    lead.lead_scaled_by_100
FROM pm10
FULL JOIN pm25_frm    ON pm10.mon = pm25_frm.mon
FULL JOIN pm25_nonfrm ON pm10.mon = pm25_nonfrm.mon
FULL JOIN voc         ON pm10.mon = voc.mon
FULL JOIN so2         ON pm10.mon = so2.mon
FULL JOIN lead        ON pm10.mon = lead.mon
ORDER BY "month"
;