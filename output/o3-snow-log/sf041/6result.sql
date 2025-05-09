/*--------------------------------------------------------------
 ERCOT – Daily Market-Dynamics Report
 Date requested : 2022-10-01  (24 hourly rows)
 Driving table  : “hours” generator guarantees one row per hour
----------------------------------------------------------------*/
WITH
/*------------------------  24-hour skeleton  -------------------*/
hours AS (
    SELECT
        DATEADD(hour, SEQ4(), '2022-10-01 00:00:00'::TIMESTAMP_NTZ)
        AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/*----------------  Day-ahead / Real-time price data  -----------*/
price AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("TIMEZONE")               AS "TIMEZONE",
        MAX("DALMP")                  AS "DALMP",
        MAX("RTLMP")                  AS "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND "DATETIME" BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*---------------------  Load forecast (19060)  -----------------*/
load_f AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("VALUE")                  AS "LOAD_FORECAST_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 19060
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*---------------------  Real-time load (9641)  -----------------*/
load_rt AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("VALUE")                  AS "RTLOAD_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9641
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*------------------  Wind forecast (9285)  ---------------------*/
wind_f AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("VALUE")                  AS "WIND_FORECAST_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9285
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*------------------  Solar forecast (662)  ---------------------*/
solar_f AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("VALUE")                  AS "SOLAR_FORECAST_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 662
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*-------------  Actual wind gen (16, average 5-min) ------------*/
wind_rt AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "WIND_GEN_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*-------------  Actual solar gen (650, average 5-min) ----------*/
solar_rt AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "SOLAR_GEN_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND "DATETIME"  BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
),
/*---------------  Peak / off-peak classification  --------------*/
peaks AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        MAX("TIMEZONE") AS "TIMEZONE",
        MAX("ONPEAK")   AS "ONPEAK",
        MAX("OFFPEAK")  AS "OFFPEAK",
        MAX("WEPEAK")   AS "WEPEAK",
        MAX("WDPEAK")   AS "WDPEAK"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE"
    WHERE "ISO" = 'ERCOT'
      AND "DATETIME" BETWEEN '2022-10-01 00:00:00' AND '2022-10-01 23:59:59'
    GROUP BY 1
)
/*===========================  FINAL  ===========================*/
SELECT
    h."DATETIME",
    COALESCE(p."TIMEZONE", peaks."TIMEZONE")                 AS "TIMEZONE",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST_MW",
    lr."RTLOAD_MW",
    wf."WIND_FORECAST_MW",
    wr."WIND_GEN_MW",
    sf."SOLAR_FORECAST_MW",
    sr."SOLAR_GEN_MW",
    /*----------  Derived Net-Load metrics  ----------*/
    CASE
        WHEN lf."LOAD_FORECAST_MW" IS NULL THEN NULL
        ELSE lf."LOAD_FORECAST_MW"
             - COALESCE(wf."WIND_FORECAST_MW",0)
             - COALESCE(sf."SOLAR_FORECAST_MW",0)
    END                                                     AS "NET_LOAD_FORECAST_MW",
    CASE
        WHEN lr."RTLOAD_MW" IS NULL THEN NULL
        ELSE lr."RTLOAD_MW"
             - COALESCE(wr."WIND_GEN_MW",0)
             - COALESCE(sr."SOLAR_GEN_MW",0)
    END                                                     AS "NET_LOAD_REALTIME_MW",
    peaks."ONPEAK",
    peaks."OFFPEAK",
    peaks."WEPEAK",
    peaks."WDPEAK"
FROM        hours      h
LEFT  JOIN  price      p   ON h."DATETIME" = p."DATETIME"
LEFT  JOIN  load_f     lf  ON h."DATETIME" = lf."DATETIME"
LEFT  JOIN  load_rt    lr  ON h."DATETIME" = lr."DATETIME"
LEFT  JOIN  wind_f     wf  ON h."DATETIME" = wf."DATETIME"
LEFT  JOIN  wind_rt    wr  ON h."DATETIME" = wr."DATETIME"
LEFT  JOIN  solar_f    sf  ON h."DATETIME" = sf."DATETIME"
LEFT  JOIN  solar_rt   sr  ON h."DATETIME" = sr."DATETIME"
LEFT  JOIN  peaks      peaks ON h."DATETIME" = peaks."DATETIME"
ORDER BY     h."DATETIME";