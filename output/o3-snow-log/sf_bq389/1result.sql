WITH
-- PM10 monthly averages
pm10 AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean")                                 AS "pm10_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM10_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
),

-- PM2.5-FRM monthly averages
pm25_frm AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean")                                 AS "pm25_frm_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_FRM_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
),

-- PM2.5-Non-FRM monthly averages
pm25_nonfrm AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean")                                 AS "pm25_nonfrm_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."PM25_NONFRM_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
),

-- VOC monthly averages
voc AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean")                                 AS "voc_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."VOC_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
),

-- SO2 monthly averages (scaled by 10)
so2_scaled AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean") * 10                            AS "so2_scaled_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."SO2_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
),

-- Lead monthly averages (scaled by 100)
lead_scaled AS (
    SELECT
        DATE_TRUNC('month', "date_local")                      AS "mth",
        AVG("arithmetic_mean") * 100                           AS "lead_scaled_avg"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY."LEAD_DAILY_SUMMARY"
    WHERE "state_name" = 'California'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY 1
)

-- Combine all pollutant monthly averages
SELECT
    COALESCE(p10."mth",
             p25f."mth",
             p25n."mth",
             v."mth",
             s."mth",
             pb."mth")                                         AS "month",
    p10."pm10_avg",
    p25f."pm25_frm_avg",
    p25n."pm25_nonfrm_avg",
    v."voc_avg",
    s."so2_scaled_avg",
    pb."lead_scaled_avg"
FROM        pm10        p10
FULL JOIN   pm25_frm    p25f ON p10."mth" = p25f."mth"
FULL JOIN   pm25_nonfrm p25n ON COALESCE(p10."mth", p25f."mth") = p25n."mth"
FULL JOIN   voc         v    ON COALESCE(p10."mth", p25f."mth", p25n."mth") = v."mth"
FULL JOIN   so2_scaled  s    ON COALESCE(p10."mth", p25f."mth", p25n."mth", v."mth") = s."mth"
FULL JOIN   lead_scaled pb   ON COALESCE(p10."mth", p25f."mth", p25n."mth", v."mth", s."mth") = pb."mth"
ORDER BY "month";