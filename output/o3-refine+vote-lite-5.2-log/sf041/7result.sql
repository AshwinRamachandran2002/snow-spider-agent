/*--------------------------------------------------------------------
  ERCOT ‑ Daily Market‑Dynamics Report
  Date : 2022-10-01   |   Load‑Zone / Gen‑Zone ObjectID : 10000712973
--------------------------------------------------------------------*/
WITH hours AS (          -- 24‑hour skeleton for 1‑Oct‑2022 (local time)
    SELECT
        DATEADD('hour', seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00')) AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/*--------------------------------------------------------------------
  Peak / Off‑Peak classification.
--------------------------------------------------------------------*/
peak_flags AS (
    SELECT
        h."DATETIME",
        COALESCE(im."TIMEZONE", 'CDT')                       AS "TIMEZONE",
        COALESCE(im."ONPEAK",
                 CASE
                     WHEN DAYOFWEEK(h."DATETIME") IN (1,7) THEN 0
                     WHEN EXTRACT(hour FROM h."DATETIME") BETWEEN 7 AND 22 THEN 1
                     ELSE 0
                 END)                                        AS "ONPEAK",
        COALESCE(im."OFFPEAK",
                 CASE
                     WHEN DAYOFWEEK(h."DATETIME") IN (1,7) THEN 1
                     WHEN EXTRACT(hour FROM h."DATETIME") BETWEEN 7 AND 22 THEN 0
                     ELSE 1
                 END)                                        AS "OFFPEAK",
        COALESCE(im."WEPEAK",
                 CASE
                     WHEN DAYOFWEEK(h."DATETIME") IN (1,7)
                          AND EXTRACT(hour FROM h."DATETIME") BETWEEN 7 AND 22
                     THEN 1
                     ELSE 0
                 END)                                        AS "WEPEAK",
        COALESCE(im."WDPEAK",
                 CASE
                     WHEN DAYOFWEEK(h."DATETIME") NOT IN (1,7)
                          AND EXTRACT(hour FROM h."DATETIME") BETWEEN 7 AND 22
                     THEN 1
                     ELSE 0
                 END)                                        AS "WDPEAK",
        COALESCE(im."MARKETDAY", DATE(h."DATETIME"))         AS "MARKETDAY",
        'ERCOT'                                              AS "ISO"
    FROM hours h
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" im
      ON im."ISO" = 'ERCOT'
     AND im."DATETIME" = h."DATETIME"
),

/*--------------------------------------------------------------------
  HB_NORTH Day‑Ahead & Real‑Time LMP
--------------------------------------------------------------------*/
price AS (
    SELECT
        "DATETIME",
        "DALMP",
        "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2022-10-01'
),

/*--------------------------------------------------------------------
  Load Forecast  (DATATYPEID = 19060) – latest publication per hour
--------------------------------------------------------------------*/
load_forecast AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "LOAD_FORECAST",
        "PUBLISHDATE" AS "LOAD_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY "DATETIME" ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973
          AND f."DATATYPEID" = 19060
          AND DATE(f."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),

/*--------------------------------------------------------------------
  Actual Load – hourly average from 5‑min samples
--------------------------------------------------------------------*/
actual_load AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "ACTUAL_LOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY DATE_TRUNC('hour', "DATETIME")
),

/*--------------------------------------------------------------------
  Wind Generation  (forecast id = 9285 , actual id = 16)
--------------------------------------------------------------------*/
wind_forecast AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "WIND_GEN_FORECAST",
        "PUBLISHDATE" AS "WIND_GEN_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY "DATETIME" ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973
          AND f."DATATYPEID" = 9285
          AND DATE(f."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
wind_actual AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "WIND_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY DATE_TRUNC('hour', "DATETIME")
),

/*--------------------------------------------------------------------
  Solar Generation  (forecast id = 662 , actual id = 650)
--------------------------------------------------------------------*/
solar_forecast AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "SOLAR_GEN_FORECAST",
        "PUBLISHDATE" AS "SOLAR_GEN_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY "DATETIME" ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973
          AND f."DATATYPEID" = 662
          AND DATE(f."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
solar_actual AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "SOLAR_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY DATE_TRUNC('hour', "DATETIME")
)

/*--------------------------------------------------------------------
  Final Report
--------------------------------------------------------------------*/
SELECT
    pf."ISO",
    pf."DATETIME",
    pf."TIMEZONE",
    pf."ONPEAK",
    pf."OFFPEAK",
    pf."WEPEAK",
    pf."WDPEAK",
    pf."MARKETDAY",
    'HB_NORTH'      AS "PRICE_NODE_NAME",
    10000697078     AS "PRICE_NODE_ID",
    pr."DALMP",
    pr."RTLMP",
    'NORTH (ERCOT)' AS "LOAD_ZONE_NAME",
    10000712973     AS "LOAD_ZONE_ID",
    lf."LOAD_FORECAST",
    lf."LOAD_FORECAST_PUBLISH_DATE",
    al."ACTUAL_LOAD"                    AS "RTLOAD",
    wf."WIND_GEN_FORECAST",
    wf."WIND_GEN_FORECAST_PUBLISH_DATE",
    wa."WIND_GEN",
    sf."SOLAR_GEN_FORECAST",
    sf."SOLAR_GEN_FORECAST_PUBLISH_DATE",
    sa."SOLAR_GEN",
    /* Net‑Load Calculations */
    COALESCE(lf."LOAD_FORECAST",0)
      - COALESCE(wf."WIND_GEN_FORECAST",0)
      - COALESCE(sf."SOLAR_GEN_FORECAST",0)     AS "NET_LOAD_FORECAST",
    COALESCE(al."ACTUAL_LOAD",0)
      - COALESCE(wa."WIND_GEN",0)
      - COALESCE(sa."SOLAR_GEN",0)              AS "NET_LOAD_REAL_TIME"
FROM peak_flags      pf
LEFT JOIN price           pr ON pf."DATETIME" = pr."DATETIME"
LEFT JOIN load_forecast   lf ON pf."DATETIME" = lf."DATETIME"
LEFT JOIN actual_load     al ON pf."DATETIME" = al."DATETIME"
LEFT JOIN wind_forecast   wf ON pf."DATETIME" = wf."DATETIME"
LEFT JOIN wind_actual     wa ON pf."DATETIME" = wa."DATETIME"
LEFT JOIN solar_forecast  sf ON pf."DATETIME" = sf."DATETIME"
LEFT JOIN solar_actual    sa ON pf."DATETIME" = sa."DATETIME"
ORDER BY pf."DATETIME" ASC;