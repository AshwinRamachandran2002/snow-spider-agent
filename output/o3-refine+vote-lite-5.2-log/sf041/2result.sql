WITH hours_src AS (  -- 24 ERCOT local hours for 1‑Oct‑2022
    SELECT DATEADD(hour, seq4(), '2022-10-01 00:00:00'::TIMESTAMP_NTZ) AS "DATETIME_LOCAL"
    FROM  TABLE(GENERATOR(ROWCOUNT => 24))
),       
base_hours AS (      -- add TZ stamp, UTC stamp & peak flags
    SELECT
        "DATETIME_LOCAL"                                    AS "DATETIME",
        'CDT'                                               AS "TIMEZONE",
        CONVERT_TIMEZONE('America/Chicago','UTC',"DATETIME_LOCAL")  AS "DATETIME_UTC",
        CASE WHEN DAYOFWEEK("DATETIME_LOCAL") BETWEEN 2 AND 6 
                  AND EXTRACT(hour FROM "DATETIME_LOCAL") BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                             AS "ONPEAK",
        CASE WHEN NOT (DAYOFWEEK("DATETIME_LOCAL") BETWEEN 2 AND 6 
                  AND EXTRACT(hour FROM "DATETIME_LOCAL") BETWEEN 7 AND 22)
             THEN 1 ELSE 0 END                             AS "OFFPEAK",
        CASE WHEN DAYOFWEEK("DATETIME_LOCAL") IN (1,7)
                  AND EXTRACT(hour FROM "DATETIME_LOCAL") BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                             AS "WEPEAK",
        CASE WHEN DAYOFWEEK("DATETIME_LOCAL") BETWEEN 2 AND 6
                  AND EXTRACT(hour FROM "DATETIME_LOCAL") BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                             AS "WDPEAK"
    FROM  hours_src
),  -------------------------------------------------------  PRICES
price_data AS (
    SELECT  dp."DATETIME", dp."DALMP", dp."RTLMP"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
    WHERE   dp."OBJECTID" = 10000697078
      AND   DATE(dp."DATETIME") = '2022-10-01'
),  -------------------------------------------------------  LOAD FORECAST
load_fcst AS (
    SELECT  "DATETIME",
            "VALUE"                                 AS "LOAD_FORECAST",
            "PUBLISHDATE"                          AS "LOAD_FCST_PUBDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC)             AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 19060
      AND   DATE("DATETIME") = '2022-10-01'
),
load_forecast AS (
    SELECT "DATETIME","LOAD_FORECAST","LOAD_FCST_PUBDATE"
    FROM   load_fcst WHERE rn = 1
),  -------------------------------------------------------  WIND FORECAST
wind_fcst AS (
    SELECT  "DATETIME",
            "VALUE"                                 AS "WIND_FCST",
            "PUBLISHDATE"                          AS "WIND_FCST_PUBDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC)             AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 9285
      AND   DATE("DATETIME") = '2022-10-01'
),
wind_forecast AS (
    SELECT "DATETIME","WIND_FCST","WIND_FCST_PUBDATE"
    FROM   wind_fcst WHERE rn = 1
),  -------------------------------------------------------  SOLAR FORECAST
solar_fcst AS (
    SELECT  "DATETIME",
            "VALUE"                                 AS "SOLAR_FCST",
            "PUBLISHDATE"                          AS "SOLAR_FCST_PUBDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC)             AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 662
      AND   DATE("DATETIME") = '2022-10-01'
),
solar_forecast AS (
    SELECT "DATETIME","SOLAR_FCST","SOLAR_FCST_PUBDATE"
    FROM   solar_fcst WHERE rn = 1
),  -------------------------------------------------------  ACTUAL LOAD
actual_load AS (
    SELECT  "DATETIME", "VALUE" AS "ACTUAL_LOAD"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 9641
      AND   DATE("DATETIME") = '2022-10-01'
),  -------------------------------------------------------  WIND ACTUAL  (15‑min → hr avg)
wind_actual AS (
    SELECT  DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
            AVG("VALUE")                  AS "WIND_ACTUAL"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 16
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),  -------------------------------------------------------  SOLAR ACTUAL (15‑min → hr avg)
solar_actual AS (
    SELECT  DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
            AVG("VALUE")                  AS "SOLAR_ACTUAL"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 650
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),  -------------------------------------------------------  STATIC METADATA
price_node AS (
    SELECT "OBJECTID","OBJECTNAME"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE"
    WHERE  "OBJECTID" = 10000697078
),
load_zone AS (
    SELECT "OBJECTID","OBJECTNAME"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE"
    WHERE  "OBJECTID" = 10000712973
)
SELECT
    'ERCOT'                               AS "ISO",
    bh."DATETIME",
    bh."TIMEZONE",
    bh."DATETIME_UTC",
    bh."ONPEAK",
    bh."OFFPEAK",
    bh."WEPEAK",
    bh."WDPEAK",
    pn."OBJECTNAME"                       AS "PRICE_NODE_NAME",
    pn."OBJECTID"                         AS "PRICE_NODE_ID",
    pr."DALMP",
    pr."RTLMP",
    lz."OBJECTNAME"                       AS "LOAD_ZONE_NAME",
    lz."OBJECTID"                         AS "LOAD_ZONE_ID",
    lf."LOAD_FORECAST",
    lf."LOAD_FCST_PUBDATE",
    al."ACTUAL_LOAD"                      AS "RTLOAD",
    wf."WIND_FCST"                        AS "WIND_GEN_FORECAST",
    wf."WIND_FCST_PUBDATE",
    sf."SOLAR_FCST"                       AS "SOLAR_GEN_FORECAST",
    sf."SOLAR_FCST_PUBDATE",
    wa."WIND_ACTUAL"                      AS "WIND_GEN_ACTUAL",
    sa."SOLAR_ACTUAL"                     AS "SOLAR_GEN_ACTUAL",
    COALESCE(lf."LOAD_FORECAST",0)
      - COALESCE(wf."WIND_FCST",0)
      - COALESCE(sf."SOLAR_FCST",0)       AS "NET_LOAD_FORECAST",
    COALESCE(al."ACTUAL_LOAD",0)
      - COALESCE(wa."WIND_ACTUAL",0)
      - COALESCE(sa."SOLAR_ACTUAL",0)     AS "NET_LOAD_REAL_TIME"
FROM   base_hours      bh
LEFT   JOIN price_data      pr  ON pr."DATETIME"   = bh."DATETIME"
LEFT   JOIN load_forecast   lf  ON lf."DATETIME"   = bh."DATETIME"
LEFT   JOIN wind_forecast   wf  ON wf."DATETIME"   = bh."DATETIME"
LEFT   JOIN solar_forecast  sf  ON sf."DATETIME"   = bh."DATETIME"
LEFT   JOIN actual_load     al  ON al."DATETIME"   = bh."DATETIME"
LEFT   JOIN wind_actual     wa  ON wa."DATETIME"   = bh."DATETIME"
LEFT   JOIN solar_actual    sa  ON sa."DATETIME"   = bh."DATETIME"
CROSS  JOIN price_node      pn
CROSS  JOIN load_zone       lz
ORDER  BY bh."DATETIME";