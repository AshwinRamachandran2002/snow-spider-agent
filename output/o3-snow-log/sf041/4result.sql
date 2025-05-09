/*--------------------------------------------------------------
   ERCOT Daily Market-Dynamics Report | October 1 , 2022
   – Builds a 24-hour skeleton for the day so the query
     returns one row per hour even if individual series
     are missing in the sample dataset.
----------------------------------------------------------------*/
WITH hrs AS (                                 -- 24 hourly stamps
    SELECT
        DATEADD(hour, SEQ4(), '2022-10-01 00:00:00') AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/*-------------------------  Prices  ---------------------------*/
price AS (
    SELECT
        h."DATETIME",
        COALESCE(dp."TIMEZONE", 'CPT') AS "TIMEZONE",
        dp."DALMP",
        dp."RTLMP"
    FROM hrs h
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
      ON dp."OBJECTID" = 10000697078
     AND dp."DATETIME"  = h."DATETIME"
),

/*-----------------  Load Forecast – latest per hour  ----------*/
load_forecast AS (
    SELECT *
    FROM (
        SELECT
            "DATETIME",
            "VALUE"        AS "LOAD_FORECAST_MW",
            "PUBLISHDATE"  AS "LOAD_FCAST_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 19060
          AND "DATETIME"  >= '2022-10-01 00:00:00'
          AND "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),

/*-------------------------  Actual Load  ----------------------*/
actual_load AS (
    SELECT
        "DATETIME",
        "VALUE" AS "ACTUAL_LOAD_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND "DATETIME" >= '2022-10-01 00:00:00'
      AND "DATETIME" <  '2022-10-02 00:00:00'
),

/*--------------  Wind Forecast – latest per hour  -------------*/
wind_forecast AS (
    SELECT *
    FROM (
        SELECT
            "DATETIME",
            "VALUE"        AS "WIND_FORECAST_MW",
            "PUBLISHDATE"  AS "WIND_FCAST_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 9285
          AND "DATETIME"  >= '2022-10-01 00:00:00'
          AND "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),

/*--------------------  Wind Actuals (hourly avg)  --------------*/
wind_actual AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "WIND_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('hour', "DATETIME")
),

/*--------------  Solar Forecast – latest per hour  -------------*/
solar_forecast AS (
    SELECT *
    FROM (
        SELECT
            "DATETIME",
            "VALUE"        AS "SOLAR_FORECAST_MW",
            "PUBLISHDATE"  AS "SOLAR_FCAST_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 662
          AND "DATETIME"  >= '2022-10-01 00:00:00'
          AND "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),

/*-------------------  Solar Actuals (hourly avg)  --------------*/
solar_actual AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "SOLAR_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('hour', "DATETIME")
),

/*---------------------  Peak-classification  -------------------*/
market_flags AS (
    SELECT
        "DATETIME",
        "ONPEAK",
        "OFFPEAK",
        "WEPEAK",
        "WDPEAK"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE"
    WHERE "ISO" = 'ERCOT'
      AND "DATETIME" >= '2022-10-01 00:00:00'
      AND "DATETIME" <  '2022-10-02 00:00:00'
)

/*----------------------  Final Report  -------------------------*/
SELECT
    'ERCOT'                                           AS "ISO",
    h."DATETIME",
    p."TIMEZONE",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST_MW",
    lf."LOAD_FCAST_PUBLISHDATE",
    al."ACTUAL_LOAD_MW",
    wf."WIND_FORECAST_MW",
    wf."WIND_FCAST_PUBLISHDATE",
    wa."WIND_ACTUAL_MW",
    sf."SOLAR_FORECAST_MW",
    sf."SOLAR_FCAST_PUBLISHDATE",
    sa."SOLAR_ACTUAL_MW",
    (lf."LOAD_FORECAST_MW"
       - (COALESCE(wf."WIND_FORECAST_MW",0)
          + COALESCE(sf."SOLAR_FORECAST_MW",0)))      AS "NET_LOAD_FORECAST_MW",
    (al."ACTUAL_LOAD_MW"
       - (COALESCE(wa."WIND_ACTUAL_MW",0)
          + COALESCE(sa."SOLAR_ACTUAL_MW",0)))        AS "NET_LOAD_REAL_TIME_MW",
    mf."ONPEAK",
    mf."OFFPEAK",
    mf."WEPEAK",
    mf."WDPEAK"
FROM hrs             h
LEFT JOIN price             p  ON p."DATETIME" = h."DATETIME"
LEFT JOIN load_forecast     lf ON lf."DATETIME" = h."DATETIME"
LEFT JOIN actual_load       al ON al."DATETIME" = h."DATETIME"
LEFT JOIN wind_forecast     wf ON wf."DATETIME" = h."DATETIME"
LEFT JOIN wind_actual       wa ON wa."DATETIME" = h."DATETIME"
LEFT JOIN solar_forecast    sf ON sf."DATETIME" = h."DATETIME"
LEFT JOIN solar_actual      sa ON sa."DATETIME" = h."DATETIME"
LEFT JOIN market_flags      mf ON mf."DATETIME" = h."DATETIME"
ORDER BY h."DATETIME";