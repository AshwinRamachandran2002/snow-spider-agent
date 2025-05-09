/*  ERCOT – Daily Market Dynamics  |  01‑Oct‑2022  */

WITH hr AS (   -- build 24 hourly rows for 2022‑10‑01 (local CDT)
    SELECT
        DATEADD(hour, seq4(), '2022-10-01 00:00:00'::TIMESTAMP_NTZ) AS datetime,
        'CDT'                                                       AS timezone,
        CASE
            WHEN DAYOFWEEK(DATEADD(hour, seq4(), '2022-10-01 00:00:00')) IN (1,7)
                 THEN 'WEPEAK'
            WHEN HOUR(DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
                 THEN 'ONPEAK'
            ELSE 'OFFPEAK'
        END                                                         AS peak_classification
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* Day‑ahead & real‑time prices */
prices AS (
    SELECT
        "DATETIME",
        "DALMP"::FLOAT AS dalmp,
        "RTLMP"::FLOAT AS rtlmp
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND "RTFINAL"  = 'Y'
      AND "DATETIME" BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
),

/* Latest‑vintage forecasts */
fcst AS (
    SELECT
        "DATETIME",
        MAX_BY("VALUE","PUBLISHDATE")::FLOAT  AS val,
        "DATATYPEID"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND "DATETIME" BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
      AND "DATATYPEID" IN (19060,9285,662)
    GROUP BY "DATETIME","DATATYPEID"
),
load_fcst  AS (SELECT "DATETIME", val AS load_forecast_mw  FROM fcst WHERE "DATATYPEID" = 19060),
wind_fcst  AS (SELECT "DATETIME", val AS wind_forecast_mw  FROM fcst WHERE "DATATYPEID" = 9285),
solar_fcst AS (SELECT "DATETIME", val AS solar_forecast_mw FROM fcst WHERE "DATATYPEID" = 662),

/* Actuals */
load_act AS (
    SELECT "DATETIME",
           "VALUE"::FLOAT AS load_actual_mw
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE  "OBJECTID" = 10000712973
      AND  "DATETIME" BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
),
wind_act AS (
    SELECT DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
           AVG("VALUE")::FLOAT           AS wind_actual_mw
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 16
      AND  "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
solar_act AS (
    SELECT DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
           AVG("VALUE")::FLOAT           AS solar_actual_mw
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 650
      AND  "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
)

/* Final report */
SELECT
    TO_CHAR(hr.datetime,'YYYY-MM-DD HH24:MI:SS')                        AS timestamp_cpt,
    hr.timezone                                                         AS timezone,
    hr.peak_classification                                              AS peak_classification,
    COALESCE(ROUND(prices.dalmp,4), 0.0000)        AS "day_ahead_price_$/MWh",
    COALESCE(ROUND(prices.rtlmp,4), 0.0000)        AS "real_time_price_$/MWh",
    COALESCE(ROUND(load_fcst.load_forecast_mw,4), 0.0000)               AS load_forecast_MW,
    COALESCE(ROUND(load_act.load_actual_mw,4),   0.0000)                AS load_actual_MW,
    COALESCE(ROUND(wind_fcst.wind_forecast_mw,4), 0.0000)               AS wind_forecast_MW,
    COALESCE(ROUND(wind_act.wind_actual_mw,4),   0.0000)                AS wind_actual_MW,
    COALESCE(ROUND(solar_fcst.solar_forecast_mw,4),0.0000)              AS solar_forecast_MW,
    COALESCE(ROUND(solar_act.solar_actual_mw,4), 0.0000)                AS solar_actual_MW,
    ROUND(
          COALESCE(load_act.load_actual_mw,0)
        - COALESCE(wind_act.wind_actual_mw,0)
        - COALESCE(solar_act.solar_actual_mw,0)
    ,4)                                                                 AS net_load_MW
FROM       hr
LEFT JOIN  prices      ON hr.datetime = prices."DATETIME"
LEFT JOIN  load_fcst   ON hr.datetime = load_fcst."DATETIME"
LEFT JOIN  load_act    ON hr.datetime = load_act."DATETIME"
LEFT JOIN  wind_fcst   ON hr.datetime = wind_fcst."DATETIME"
LEFT JOIN  wind_act    ON hr.datetime = wind_act."DATETIME"
LEFT JOIN  solar_fcst  ON hr.datetime = solar_fcst."DATETIME"
LEFT JOIN  solar_act   ON hr.datetime = solar_act."DATETIME"
ORDER BY   hr.datetime;