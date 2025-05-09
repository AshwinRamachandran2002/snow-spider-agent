/*====================================================================
  ERCOT • 01-Oct-2022  |  Hourly Market-Dynamics Roll-Up
  ‑- Robust timeline generator guarantees a 24-row report even if
     some underlying series have no records for the chosen day.
====================================================================*/
WITH hours AS (  -- 24 hourly stamps for 2022-10-01 (local ERCOT clock)
    SELECT
        DATEADD('hour', SEQ4(), '2022-10-01'::TIMESTAMP_NTZ) AS "HR"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* ---------------------------  Prices  --------------------------- */
price AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")       AS "HR",
        MAX("DALMP")::FLOAT                 AS "DALMP",
        MAX("RTLMP")::FLOAT                 AS "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND "DATETIME" >= '2022-10-01'::TIMESTAMP_NTZ
      AND "DATETIME" <  '2022-10-02'::TIMESTAMP_NTZ
    GROUP BY 1
),

/* ----------------------  Load – Forecast  ----------------------- */
load_forecast AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")                       AS "HR",
        "VALUE"::FLOAT                                      AS "LOAD_FORECAST_MW"
    FROM (
        SELECT
            "DATETIME","VALUE","PUBLISHDATE",
            ROW_NUMBER() OVER (
                PARTITION BY DATE_TRUNC('hour',"DATETIME")
                ORDER BY      "PUBLISHDATE" DESC
            ) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 19060
          AND "DATETIME" >= '2022-10-01'
          AND "DATETIME" <  '2022-10-02'
    )
    WHERE rn = 1
),

/* ----------------------  Load – Real-Time  ---------------------- */
rt_load AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")       AS "HR",
        AVG("LOAD")::FLOAT                  AS "RTLOAD_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."RT_LOADS_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND "DATETIME" >= '2022-10-01'
      AND "DATETIME" <  '2022-10-02'
    GROUP BY 1
),

/* ---------------------  Wind – Forecast  ------------------------ */
wind_forecast AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")                       AS "HR",
        "VALUE"::FLOAT                                      AS "WIND_FORECAST_MW"
    FROM (
        SELECT
            "DATETIME","VALUE","PUBLISHDATE",
            ROW_NUMBER() OVER (
                PARTITION BY DATE_TRUNC('hour',"DATETIME")
                ORDER BY      "PUBLISHDATE" DESC
            ) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 9285
          AND "DATETIME" >= '2022-10-01'
          AND "DATETIME" <  '2022-10-02'
    )
    WHERE rn = 1
),

/* ----------------------  Wind – Actual  ------------------------- */
wind_actual AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")       AS "HR",
        AVG("VALUE")::FLOAT                 AS "WIND_GEN_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16          -- Wind actual
      AND "DATETIME" >= '2022-10-01'
      AND "DATETIME" <  '2022-10-02'
    GROUP BY 1
),

/* ---------------------  Solar – Forecast  ----------------------- */
solar_forecast AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")                       AS "HR",
        "VALUE"::FLOAT                                      AS "SOLAR_FORECAST_MW"
    FROM (
        SELECT
            "DATETIME","VALUE","PUBLISHDATE",
            ROW_NUMBER() OVER (
                PARTITION BY DATE_TRUNC('hour',"DATETIME")
                ORDER BY      "PUBLISHDATE" DESC
            ) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 662
          AND "DATETIME" >= '2022-10-01'
          AND "DATETIME" <  '2022-10-02'
    )
    WHERE rn = 1
),

/* ----------------------  Solar – Actual  ------------------------ */
solar_actual AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")       AS "HR",
        AVG("VALUE")::FLOAT                 AS "SOLAR_GEN_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650         -- Solar actual
      AND "DATETIME" >= '2022-10-01'
      AND "DATETIME" <  '2022-10-02'
    GROUP BY 1
),

/* ------------------  Peak / Off-Peak Flags  --------------------- */
market_times AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME")       AS "HR",
        MAX("TIMEZONE")         AS "TIMEZONE",
        MAX("DATETIME_UTC")     AS "DATETIME_UTC",
        MAX("ONPEAK")           AS "ONPEAK",
        MAX("OFFPEAK")          AS "OFFPEAK",
        MAX("WEPEAK")           AS "WEPEAK",
        MAX("WDPEAK")           AS "WDPEAK"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE"
    WHERE "ISO" = 'ERCOT'
      AND "DATETIME" >= '2022-10-01'
      AND "DATETIME" <  '2022-10-02'
    GROUP BY 1
)

/* ===========================  Final Report  =========================== */
SELECT
    h."HR"                                    AS "DATETIME",
    mt."TIMEZONE",
    mt."DATETIME_UTC",
    mt."ONPEAK",
    mt."OFFPEAK",
    mt."WEPEAK",
    mt."WDPEAK",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST_MW",
    rl."RTLOAD_MW",
    wf."WIND_FORECAST_MW",
    wa."WIND_GEN_MW",
    sf."SOLAR_FORECAST_MW",
    sa."SOLAR_GEN_MW",
    /* -----------------  Net-Load Calculations  ----------------- */
    ( COALESCE(lf."LOAD_FORECAST_MW",0)
      - COALESCE(wf."WIND_FORECAST_MW",0)
      - COALESCE(sf."SOLAR_FORECAST_MW",0) )  AS "NET_LOAD_FORECAST_MW",
    ( COALESCE(rl."RTLOAD_MW",0)
      - COALESCE(wa."WIND_GEN_MW",0)
      - COALESCE(sa."SOLAR_GEN_MW",0) )       AS "NET_LOAD_REALTIME_MW"
FROM hours               h
LEFT JOIN market_times   mt ON h."HR" = mt."HR"
LEFT JOIN price          p  ON h."HR" = p."HR"
LEFT JOIN load_forecast  lf ON h."HR" = lf."HR"
LEFT JOIN rt_load        rl ON h."HR" = rl."HR"
LEFT JOIN wind_forecast  wf ON h."HR" = wf."HR"
LEFT JOIN wind_actual    wa ON h."HR" = wa."HR"
LEFT JOIN solar_forecast sf ON h."HR" = sf."HR"
LEFT JOIN solar_actual   sa ON h."HR" = sa."HR"
ORDER BY h."HR" ASC;