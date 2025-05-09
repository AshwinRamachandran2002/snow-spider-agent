/*--------------------------------------------------------------
  ERCOT ‒ Daily Operational Dynamics Report
  Date: 01-Oct-2022  (local ERCOT time)
----------------------------------------------------------------*/

WITH
/*--- 24 hourly time-stamps for the study day -----------------*/
hours AS (
    SELECT
        DATEADD(hour, seq4(), '2022-10-01 00:00:00'::TIMESTAMP_NTZ) AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/*-------------  Hourly Load-Zone Forecast --------------------*/
load_forecast AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT)                AS "LOAD_FORECAST",
        "PUBLISHDATE"                         AS "LOAD_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  t.*,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE t
        WHERE t."OBJECTID"   = 10000712973       -- ERCOT load-zone
          AND t."DATATYPEID" = 19060             -- 7-day hourly load forecast
    )
    WHERE rn = 1
),

/*-------------  Actual Hourly Load ---------------------------*/
load_actual AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT) AS "RTLOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_LOAD_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9641
),

/*-------------  Wind Forecast --------------------------------*/
wind_forecast AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT)         AS "WIND_FORECAST",
        "PUBLISHDATE"                  AS "WIND_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  t.*,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE t
        WHERE t."OBJECTID"   = 10000712973
          AND t."DATATYPEID" = 9285
    )
    WHERE rn = 1
),

/*-------------  Wind Actual ----------------------------------*/
wind_actual AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT) AS "WIND_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
),

/*-------------  Solar Forecast -------------------------------*/
solar_forecast AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT)         AS "SOLAR_FORECAST",
        "PUBLISHDATE"                  AS "SOLAR_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  t.*,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE t
        WHERE t."OBJECTID"   = 10000712973
          AND t."DATATYPEID" = 662
    )
    WHERE rn = 1
),

/*-------------  Solar Actual ---------------------------------*/
solar_actual AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS FLOAT) AS "SOLAR_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
)

/*====================  Final Report  =========================*/
SELECT
    h."DATETIME"                                              AS "datetime",
    'CDT'                                                     AS "timezone",           -- Oct-01-22 is in daylight time
    CONVERT_TIMEZONE('America/Chicago', 'UTC', h."DATETIME")  AS "datetime_utc",

    m."ONPEAK",
    m."OFFPEAK",
    m."WEPEAK",
    m."WDPEAK",
    m."MARKETDAY",

    p."DALMP",
    p."RTLMP",

    lf."LOAD_FORECAST",
    lf."LOAD_FORECAST_PUBLISH_DATE",
    la."RTLOAD",

    wf."WIND_FORECAST",
    wf."WIND_FORECAST_PUBLISH_DATE",
    wa."WIND_GEN",

    sf."SOLAR_FORECAST",
    sf."SOLAR_FORECAST_PUBLISH_DATE",
    sa."SOLAR_GEN",

    /*----- Derived Metrics -----------------------------------*/
    COALESCE(lf."LOAD_FORECAST",0)
      - (COALESCE(wf."WIND_FORECAST",0) + COALESCE(sf."SOLAR_FORECAST",0))
        AS "NET_LOAD_FORECAST",

    COALESCE(la."RTLOAD",0)
      - (COALESCE(wa."WIND_GEN",0) + COALESCE(sa."SOLAR_GEN",0))
        AS "NET_LOAD_REAL_TIME"

FROM hours h

/* ISO market-time flags (weekday/weekend peak definitions) */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.ISO_MARKET_TIMES_SAMPLE m
       ON h."DATETIME" = m."DATETIME"
      AND m."ISO"      = 'ERCOT'

/* Day-ahead & real-time prices */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.DART_PRICES_SAMPLE p
       ON h."DATETIME" = p."DATETIME"
      AND p."OBJECTID" = 10000697078          -- price node HB_NORTH

/* Load, wind, solar data */
LEFT JOIN load_forecast  lf ON h."DATETIME" = lf."DATETIME"
LEFT JOIN load_actual    la ON h."DATETIME" = la."DATETIME"
LEFT JOIN wind_forecast  wf ON h."DATETIME" = wf."DATETIME"
LEFT JOIN wind_actual    wa ON h."DATETIME" = wa."DATETIME"
LEFT JOIN solar_forecast sf ON h."DATETIME" = sf."DATETIME"
LEFT JOIN solar_actual   sa ON h."DATETIME" = sa."DATETIME"

ORDER BY h."DATETIME";