/*--------------------------------------------------------------
  ERCOT – Daily Market‑Dynamics Report
  Date : 01‑Oct‑2022
  Prices  : OBJECTID 10000697078
  Load/Gen: OBJECTID 10000712973
--------------------------------------------------------------*/
WITH hours AS (   /* 24‑hour timeline (Central Time) with peak flags */
    SELECT
        DATEADD(hour, seq4(), '2022-10-01 00:00:00')::TIMESTAMP_NTZ                           AS "DATETIME",
        'CDT'                                                                                 AS "TIMEZONE",
        CONVERT_TIMEZONE('America/Chicago', 'UTC',
                         DATEADD(hour, seq4(), '2022-10-01 00:00:00'))::TIMESTAMP_NTZ         AS "DATETIME_UTC",
        /* ERCOT on‑peak 07:00‑22:00 Mon‑Fri */
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                                               AS "ONPEAK",
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 0 ELSE 1 END                                                               AS "OFFPEAK",
        /* weekend peak 07:00‑22:00 Sat‑Sun */
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) IN (0,6)
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                                               AS "WEPEAK",
        /* weekday‑peak flag */
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                                               AS "WDPEAK"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/* ---------------- prices ------------------------------------------------ */
dart_prices AS (
    SELECT  "DATETIME",
            ROUND("DALMP"::FLOAT , 4)                           AS "DALMP",
            ROUND("RTLMP"::FLOAT , 4)                           AS "RTLMP_DART"
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE   "OBJECTID" = 10000697078
      AND   "DATETIME" >= '2022-10-01 00:00:00'
      AND   "DATETIME" <  '2022-10-02 00:00:00'
),
rt15_hourly AS (   /* real‑time price back‑fill using 15‑minute data */
    SELECT  DATE_TRUNC('hour',"DATETIME")                       AS "DATETIME",
            ROUND(AVG("LMP")::FLOAT , 4)                        AS "RTLMP_RT15"
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."RT15_PRICES_SAMPLE"
    WHERE   "OBJECTID" = 10000697078
      AND   "DATETIME" >= '2022-10-01 00:00:00'
      AND   "DATETIME" <  '2022-10-02 00:00:00'
    GROUP BY 1
),
prices AS (
    SELECT  h."DATETIME",
            dp."DALMP",
            COALESCE(dp."RTLMP_DART", r15."RTLMP_RT15")         AS "RTLMP"
    FROM    hours h
    LEFT JOIN dart_prices dp  USING ("DATETIME")
    LEFT JOIN rt15_hourly r15 USING ("DATETIME")
),
/* ---------------- load forecast (datatypeid 19060) -------------------- */
load_fcst AS (
    SELECT  "DATETIME",
            ROUND("VALUE"::FLOAT , 4)                           AS "LOAD_FORECAST",
            "PUBLISHDATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE   "OBJECTID"   = 10000712973
          AND   "DATATYPEID" = 19060
          AND   "DATETIME"  >= '2022-10-01 00:00:00'
          AND   "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),
/* ---------------- actual load ---------------------------------------- */
load_rt AS (
    SELECT  "DATETIME",
            ROUND("VALUE"::FLOAT , 4) AS "RTLOAD"
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE   "OBJECTID" = 10000712973
      AND   "DATETIME" >= '2022-10-01 00:00:00'
      AND   "DATETIME" <  '2022-10-02 00:00:00'
),
/* ---------------- wind forecast & actual ------------------------------ */
wind_fcst AS (
    SELECT  "DATETIME",
            ROUND("VALUE"::FLOAT , 4)                           AS "WIND_FORECAST",
            "PUBLISHDATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE   "OBJECTID"   = 10000712973
          AND   "DATATYPEID" = 9285
          AND   "DATETIME"  >= '2022-10-01 00:00:00'
          AND   "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),
wind_rt AS (
    SELECT  DATE_TRUNC('hour',"DATETIME")                       AS "DATETIME",
            ROUND(AVG("VALUE")::FLOAT , 4)                      AS "WIND_ACTUAL"
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 16
      AND   "DATETIME"  >= '2022-10-01 00:00:00'
      AND   "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY 1
),
/* ---------------- solar forecast & actual ----------------------------- */
solar_fcst AS (
    SELECT  "DATETIME",
            ROUND("VALUE"::FLOAT , 4)                           AS "SOLAR_FORECAST",
            "PUBLISHDATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE   "OBJECTID"   = 10000712973
          AND   "DATATYPEID" = 662
          AND   "DATETIME"  >= '2022-10-01 00:00:00'
          AND   "DATETIME"  <  '2022-10-02 00:00:00'
    )
    WHERE rn = 1
),
solar_rt AS (
    SELECT  DATE_TRUNC('hour',"DATETIME")                       AS "DATETIME",
            ROUND(AVG("VALUE")::FLOAT , 4)                      AS "SOLAR_ACTUAL"
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 650
      AND   "DATETIME"  >= '2022-10-01 00:00:00'
      AND   "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY 1
)
/* ---------------- final report ---------------------------------------- */
SELECT
    h."DATETIME",
    h."TIMEZONE",
    h."DATETIME_UTC",
    h."ONPEAK",
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",
    pr."DALMP",
    pr."RTLMP",
    lf."LOAD_FORECAST",
    lf."PUBLISHDATE"                        AS "LOAD_FORECAST_PUBLISHDATE",
    lr."RTLOAD",
    wf."WIND_FORECAST",
    wf."PUBLISHDATE"                        AS "WIND_FORECAST_PUBLISHDATE",
    wr."WIND_ACTUAL",
    sf."SOLAR_FORECAST",
    sf."PUBLISHDATE"                        AS "SOLAR_FORECAST_PUBLISHDATE",
    sr."SOLAR_ACTUAL",
    ROUND(lf."LOAD_FORECAST"
          - COALESCE(wf."WIND_FORECAST",0)
          - COALESCE(sf."SOLAR_FORECAST",0), 4)                 AS "NET_LOAD_FORECAST",
    ROUND(lr."RTLOAD"
          - COALESCE(wr."WIND_ACTUAL",0)
          - COALESCE(sr."SOLAR_ACTUAL",0), 4)                   AS "NET_LOAD_REAL_TIME"
FROM        hours       h
LEFT JOIN   prices      pr ON pr."DATETIME" = h."DATETIME"
LEFT JOIN   load_fcst   lf ON lf."DATETIME" = h."DATETIME"
LEFT JOIN   load_rt     lr ON lr."DATETIME" = h."DATETIME"
LEFT JOIN   wind_fcst   wf ON wf."DATETIME" = h."DATETIME"
LEFT JOIN   wind_rt     wr ON wr."DATETIME" = h."DATETIME"
LEFT JOIN   solar_fcst  sf ON sf."DATETIME" = h."DATETIME"
LEFT JOIN   solar_rt    sr ON sr."DATETIME" = h."DATETIME"
ORDER BY    h."DATETIME" ASC;