/*  ERCOT Daily Market Dynamics Report – October 1 2022  */
/*  All joins are LEFT so rows are returned even if particular data are missing                      */

WITH base_hours AS (          -- generate the 24 hourly stamps for 01-Oct-2022 (local ERCOT time)
    SELECT
        DATEADD('hour', seq4(), '2022-10-01 00:00:00') AS "DT"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

hours AS (                    -- add peak/off-peak flags and supporting columns
    SELECT
        'ERCOT'                                       AS "ISO",
        "DT"                                          AS "DATETIME",
        'CDT'                                         AS "TIMEZONE",
        CONVERT_TIMEZONE('America/Chicago','UTC',"DT") AS "DATETIME_UTC",
        /* weekday/weekend identification */
        CASE WHEN DAYOFWEEK("DT") IN (1,7)
                  AND EXTRACT(HOUR FROM "DT") BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                        AS "WEPEAK",
        CASE WHEN DAYOFWEEK("DT") NOT IN (1,7)
                  AND EXTRACT(HOUR FROM "DT") BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                        AS "WDPEAK"
    FROM base_hours
),

hours_final AS (              -- derive OFFPEAK and supply constant ONPEAK=0
    SELECT
        h.*,
        0                                                      AS "ONPEAK",
        CASE WHEN h."WEPEAK" = 0 AND h."WDPEAK" = 0 THEN 1 ELSE 0 END  AS "OFFPEAK",
        DATE_TRUNC('day', h."DATETIME")                        AS "MARKETDAY"
    FROM hours h
),

/*  price data – day-ahead and real-time  */
price AS (
    SELECT
        "DATETIME",
        "DALMP",
        "RTLMP"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2022-10-01'
),

/*  load forecast (datatype 19060) – keep the most recent publish per hour  */
load_fcst AS (
    SELECT "DATETIME",
           "VALUE"       AS "LOAD_FORECAST",
           "PUBLISHDATE" AS "LOAD_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 19060
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),

/*  actual hourly load  */
load_rt AS (
    SELECT
        "DATETIME",
        "VALUE" AS "RTLOAD"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
),

/*  wind – forecast (9285) and actual (16) */
wind_fcst AS (
    SELECT "DATETIME",
           "VALUE"       AS "WIND_GEN_FORECAST",
           "PUBLISHDATE" AS "WIND_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 9285
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
wind_rt AS (
    SELECT
        "DATETIME",
        "VALUE" AS "WIND_GEN"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND DATE("DATETIME") = '2022-10-01'
),

/*  solar – forecast (662) and actual (650) */
solar_fcst AS (
    SELECT "DATETIME",
           "VALUE"       AS "SOLAR_GEN_FORECAST",
           "PUBLISHDATE" AS "SOLAR_FORECAST_PUBLISH_DATE"
    FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 662
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
solar_rt AS (
    SELECT
        "DATETIME",
        "VALUE" AS "SOLAR_GEN"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND DATE("DATETIME") = '2022-10-01'
),

/*  constant look-ups for descriptive names  */
price_node_info AS (
    SELECT
        "OBJECTID"  AS "PRICE_NODE_ID",
        "PNODENAME" AS "PRICE_NODE_NAME"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."PRICE_NODES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
),
load_zone_info AS (
    SELECT
        "OBJECTID"   AS "LOAD_ZONE_ID",
        "OBJECTNAME" AS "LOAD_ZONE_NAME"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DS_OBJECT_LIST_SAMPLE"
    WHERE "OBJECTID" = 10000712973
)

/*  ----------  FINAL REPORT  ----------  */
SELECT
    h."ISO"                          AS "iso",
    h."DATETIME"                     AS "datetime",
    h."TIMEZONE"                     AS "timezone",
    h."DATETIME_UTC"                 AS "datetime_utc",
    h."ONPEAK"                       AS "onpeak",
    h."OFFPEAK"                      AS "offpeak",
    h."WEPEAK"                       AS "wepeak",
    h."WDPEAK"                       AS "wdpeak",
    h."MARKETDAY"                    AS "marketday",

    pni."PRICE_NODE_NAME"            AS "price_node_name",
    pni."PRICE_NODE_ID"              AS "price_node_id",
    p."DALMP"                        AS "dalmp",
    p."RTLMP"                        AS "rtlmp",

    lzi."LOAD_ZONE_NAME"             AS "load_zone_name",
    lzi."LOAD_ZONE_ID"               AS "load_zone_id",
    lf."LOAD_FORECAST"               AS "load_forecast",
    lf."LOAD_FORECAST_PUBLISH_DATE"  AS "load_forecast_publish_date",
    lr."RTLOAD"                      AS "rtload",

    wf."WIND_GEN_FORECAST"           AS "wind_gen_forecast",
    wf."WIND_FORECAST_PUBLISH_DATE"  AS "wind_gen_forecast_publish_date",
    wr."WIND_GEN"                    AS "wind_gen",

    sf."SOLAR_GEN_FORECAST"          AS "solar_gen_forecast",
    sf."SOLAR_FORECAST_PUBLISH_DATE" AS "solar_gen_forecast_publish_date",
    sr."SOLAR_GEN"                   AS "solar_gen",

    /*  derived metrics  */
    (lf."LOAD_FORECAST"
        - wf."WIND_GEN_FORECAST"
        - sf."SOLAR_GEN_FORECAST")            AS "net_load_forecast",

    (lr."RTLOAD"
        - wr."WIND_GEN"
        - sr."SOLAR_GEN")                     AS "net_load_real_time"

FROM   hours_final                h
LEFT JOIN price        p   ON h."DATETIME" = p."DATETIME"
LEFT JOIN load_fcst    lf  ON h."DATETIME" = lf."DATETIME"
LEFT JOIN load_rt      lr  ON h."DATETIME" = lr."DATETIME"
LEFT JOIN wind_fcst    wf  ON h."DATETIME" = wf."DATETIME"
LEFT JOIN wind_rt      wr  ON h."DATETIME" = wr."DATETIME"
LEFT JOIN solar_fcst   sf  ON h."DATETIME" = sf."DATETIME"
LEFT JOIN solar_rt     sr  ON h."DATETIME" = sr."DATETIME"
CROSS JOIN price_node_info pni
CROSS JOIN load_zone_info  lzi

ORDER BY h."DATETIME" ASC;