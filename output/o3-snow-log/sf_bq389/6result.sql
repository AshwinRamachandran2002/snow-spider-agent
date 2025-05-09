WITH "months" AS (   -- every month present in PM10 measurements
    SELECT DATE_TRUNC('month', "date_local") AS "month"
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM10_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* PM-10 ---------------------------------------------------------*/
"pm10" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")            AS pm10_avg_ug_m3
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM10_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* PM-2.5 FRM ----------------------------------------------------*/
"pm25_frm" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")            AS pm25_frm_avg_ug_m3
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_FRM_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* PM-2.5 non-FRM ----------------------------------------------*/
"pm25_nonfrm" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")            AS pm25_nonfrm_avg_ug_m3
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_NONFRM_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* VOC -----------------------------------------------------------*/
"voc" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")            AS voc_avg_ppbc
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."VOC_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* SO₂  (scaled ×10) --------------------------------------------*/
"so2" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")*10         AS so2_avg_ppb_x10
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."SO2_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
),

/* Lead (scaled ×100) -------------------------------------------*/
"lead" AS (
    SELECT DATE_TRUNC('month', "date_local") AS m,
           AVG("arithmetic_mean")*100        AS lead_avg_ug_m3_x100
    FROM   EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."LEAD_DAILY_SUMMARY"
    WHERE  "state_code"  = '06'
       AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP  BY 1
)

/* Final result --------------------------------------------------*/
SELECT  m."month",
        p10.pm10_avg_ug_m3,
        p25f.pm25_frm_avg_ug_m3,
        p25n.pm25_nonfrm_avg_ug_m3,
        v.voc_avg_ppbc,
        s.so2_avg_ppb_x10,
        l.lead_avg_ug_m3_x100
FROM    "months"      m
LEFT JOIN "pm10"         p10  ON m."month" = p10.m
LEFT JOIN "pm25_frm"     p25f ON m."month" = p25f.m
LEFT JOIN "pm25_nonfrm"  p25n ON m."month" = p25n.m
LEFT JOIN "voc"          v    ON m."month" = v.m
LEFT JOIN "so2"          s    ON m."month" = s.m
LEFT JOIN "lead"         l    ON m."month" = l.m
ORDER BY m."month";