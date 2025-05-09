WITH pm10 AS (  -- PM10 monthly averages
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        AVG("arithmetic_mean")           AS "pm10"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM10_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
pm25_frm AS (    -- PM2.5 FRM
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        AVG("arithmetic_mean")           AS "pm25_frm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_FRM_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
pm25_nonfrm AS ( -- PM2.5 non-FRM
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        AVG("arithmetic_mean")           AS "pm25_nonfrm"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
voc AS (         -- Volatile organic compounds
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        AVG("arithmetic_mean")           AS "voc"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.VOC_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
so2 AS (         -- SO₂ scaled ×10
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        10 * AVG("arithmetic_mean")      AS "so2_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.SO2_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
),
lead AS (        -- Lead scaled ×100
    SELECT
        EXTRACT(MONTH FROM "date_local") AS "month",
        100 * AVG("arithmetic_mean")     AS "lead_scaled"
    FROM EPA_HISTORICAL_AIR_QUALITY.EPA_HISTORICAL_AIR_QUALITY.LEAD_DAILY_SUMMARY
    WHERE "state_name" ILIKE '%California%'
      AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY EXTRACT(MONTH FROM "date_local")
)

SELECT
    COALESCE(p10."month", p25f."month", p25n."month",
             v."month",  s."month",   l."month")            AS "month",
    p10."pm10",
    p25f."pm25_frm",
    p25n."pm25_nonfrm",
    v."voc",
    s."so2_scaled",
    l."lead_scaled"
FROM pm10         AS p10
FULL JOIN pm25_frm   AS p25f ON p10."month" = p25f."month"
FULL JOIN pm25_nonfrm AS p25n ON COALESCE(p10."month", p25f."month") = p25n."month"
FULL JOIN voc          AS v   ON COALESCE(p10."month", p25f."month", p25n."month") = v."month"
FULL JOIN so2          AS s   ON COALESCE(p10."month", p25f."month", p25n."month", v."month") = s."month"
FULL JOIN lead         AS l   ON COALESCE(p10."month", p25f."month", p25n."month", v."month", s."month") = l."month"
WHERE COALESCE(p10."month", p25f."month", p25n."month",
               v."month",  s."month",   l."month") IS NOT NULL
ORDER BY "month";