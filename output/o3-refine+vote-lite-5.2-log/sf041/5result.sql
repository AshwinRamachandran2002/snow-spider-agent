/*  ERCOT ‑ Daily Market Dynamics – 01‑Oct‑2022  */
WITH params AS (                                     -- report anchor
    SELECT TO_TIMESTAMP_NTZ('2022-10-01 00:00:00') AS "day_start"
),
/* -----------------------------------------------------------------
   1) build a guaranteed 24‑row hourly frame for the report day
   ----------------------------------------------------------------- */
base_hours AS (
    SELECT
        'ERCOT'                                           AS "iso",
        DATEADD(hour, seq4(), p."day_start")              AS "datetime",
        'CDT'                                             AS "timezone",              -- Central Daylight Time on Oct‑01‑2022
        CONVERT_TIMEZONE('America/Chicago','UTC',
                         DATEADD(hour, seq4(), p."day_start"))                       AS "datetime_utc",
        TO_DATE(DATEADD(hour, seq4(), p."day_start"))     AS "marketday",
        EXTRACT(hour FROM DATEADD(hour, seq4(), p."day_start"))                      AS "hour_num"
    FROM params  p,
         TABLE(GENERATOR(ROWCOUNT => 24))
),
/* -----------------------------------------------------------------
   2) peak/off‑peak flags –‑ use ISO table when it exists, otherwise
      derive simple WD/WE rules (7:00‑22:00 local on‑peak)
   ----------------------------------------------------------------- */
peak_flags AS (
    SELECT
        bh.*,
        /* weekday / weekend tests return: 1 = Monday … 7 = Sunday  */
        CASE WHEN DAYOFWEEK(bh."datetime") BETWEEN 2 AND 6          -- Mon‑Fri
              AND bh."hour_num" BETWEEN 7 AND 21 THEN 1 ELSE 0 END  AS "wdpeak_calc",
        CASE WHEN DAYOFWEEK(bh."datetime") IN (1,7)                 -- Sat/Sun
              AND bh."hour_num" BETWEEN 7 AND 21 THEN 1 ELSE 0 END  AS "wepeak_calc"
    FROM base_hours bh
),
hours_final AS (
    SELECT
        pf."iso",
        pf."datetime",
        pf."timezone",
        pf."datetime_utc",
        COALESCE(imt."ONPEAK" , pf."wdpeak_calc" + pf."wepeak_calc")               AS "onpeak",
        COALESCE(imt."OFFPEAK", 1 - (pf."wdpeak_calc" + pf."wepeak_calc"))         AS "offpeak",
        COALESCE(imt."WEPEAK" , pf."wepeak_calc")                                  AS "wepeak",
        COALESCE(imt."WDPEAK" , pf."wdpeak_calc")                                  AS "wdpeak",
        pf."marketday"
    FROM peak_flags pf
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" imt
           ON imt."ISO" = 'ERCOT'
          AND imt."DATETIME" = pf."datetime"
),
/* -----------------------------------------------------------------
   3) static dimension look‑ups
   ----------------------------------------------------------------- */
price_node AS (
    SELECT
        dsol."OBJECTID"   AS "price_node_id",
        dsol."OBJECTNAME" AS "price_node_name"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" dsol
    WHERE dsol."OBJECTID" = 10000697078
),
load_zone AS (
    SELECT
        dsol."OBJECTID"   AS "load_zone_id",
        dsol."OBJECTNAME" AS "load_zone_name"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" dsol
    WHERE dsol."OBJECTID" = 10000712973
),
/* -----------------------------------------------------------------
   4) market & operations time‑series
   ----------------------------------------------------------------- */
price_data AS (
    SELECT
        dp."DATETIME",
        dp."DALMP"::FLOAT  AS "dalmp",
        dp."RTLMP"::FLOAT  AS "rtlmp"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
    WHERE dp."OBJECTID" = 10000697078
      AND DATE(dp."DATETIME") = '2022-10-01'
),
/* ---- Load forecast (datatypeid = 19060) – take latest publish ---- */
load_forecast AS (
    SELECT
        tf."DATETIME",
        tf."VALUE"::FLOAT       AS "load_forecast",
        tf."PUBLISHDATE"        AS "load_forecast_publish_date",
        ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                           ORDER BY tf."PUBLISHDATE" DESC) AS "rn"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
    WHERE tf."OBJECTID"   = 10000712973
      AND tf."DATATYPEID" = 19060
      AND DATE(tf."DATETIME") = '2022-10-01'
),
load_fcst AS (SELECT * FROM load_forecast WHERE "rn" = 1),
/* ---- actual load ------------------------------------------------- */
actual_load AS (
    SELECT
        tl."DATETIME",
        tl."VALUE"::FLOAT AS "rtload"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE" tl
    WHERE tl."OBJECTID" = 10000712973
      AND DATE(tl."DATETIME") = '2022-10-01'
),
/* ---- wind forecast (9285) --------------------------------------- */
wind_forecast AS (
    SELECT
        tf."DATETIME",
        tf."VALUE"::FLOAT        AS "wind_gen_forecast",
        tf."PUBLISHDATE"         AS "wind_gen_forecast_publish_date",
        ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                           ORDER BY tf."PUBLISHDATE" DESC) AS "rn"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
    WHERE tf."OBJECTID"   = 10000712973
      AND tf."DATATYPEID" = 9285
      AND DATE(tf."DATETIME") = '2022-10-01'
),
wind_fcst AS (SELECT * FROM wind_forecast WHERE "rn" = 1),
/* ---- solar forecast (662) --------------------------------------- */
solar_forecast AS (
    SELECT
        tf."DATETIME",
        tf."VALUE"::FLOAT        AS "solar_gen_forecast",
        tf."PUBLISHDATE"         AS "solar_gen_forecast_publish_date",
        ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                           ORDER BY tf."PUBLISHDATE" DESC) AS "rn"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
    WHERE tf."OBJECTID"   = 10000712973
      AND tf."DATATYPEID" = 662
      AND DATE(tf."DATETIME") = '2022-10-01'
),
solar_fcst AS (SELECT * FROM solar_forecast WHERE "rn" = 1),
/* ---- actual wind & solar generation ----------------------------- */
wind_actual AS (
    SELECT
        tg."DATETIME",
        tg."VALUE"::FLOAT AS "wind_gen"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" tg
    WHERE tg."OBJECTID"   = 10000712973
      AND tg."DATATYPEID" = 16
      AND DATE(tg."DATETIME") = '2022-10-01'
),
solar_actual AS (
    SELECT
        tg."DATETIME",
        tg."VALUE"::FLOAT AS "solar_gen"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" tg
    WHERE tg."OBJECTID"   = 10000712973
      AND tg."DATATYPEID" = 650
      AND DATE(tg."DATETIME") = '2022-10-01'
)
/* -----------------------------------------------------------------
   5) final report
   ----------------------------------------------------------------- */
SELECT
    hf."iso",
    hf."datetime",
    hf."timezone",
    hf."datetime_utc",
    hf."onpeak",
    hf."offpeak",
    hf."wepeak",
    hf."wdpeak",
    hf."marketday",

    pn."price_node_name",
    pn."price_node_id",
    pr."dalmp",
    pr."rtlmp",

    lz."load_zone_name",
    lz."load_zone_id",
    lf."load_forecast",
    lf."load_forecast_publish_date",
    al."rtload",

    wf."wind_gen_forecast",
    wf."wind_gen_forecast_publish_date",
    wa."wind_gen",

    sf."solar_gen_forecast",
    sf."solar_gen_forecast_publish_date",
    sa."solar_gen",

    /* ---------- derived KPIs ---------- */
    (lf."load_forecast" - (wf."wind_gen_forecast" + sf."solar_gen_forecast")) AS "net_load_forecast",
    (al."rtload"        - (wa."wind_gen"          + sa."solar_gen"))          AS "net_load_real_time"

FROM hours_final            hf
CROSS JOIN price_node       pn
CROSS JOIN load_zone        lz
LEFT  JOIN price_data       pr  ON pr."DATETIME" = hf."datetime"
LEFT  JOIN load_fcst        lf  ON lf."DATETIME" = hf."datetime"
LEFT  JOIN actual_load      al  ON al."DATETIME" = hf."datetime"
LEFT  JOIN wind_fcst        wf  ON wf."DATETIME" = hf."datetime"
LEFT  JOIN solar_fcst       sf  ON sf."DATETIME" = hf."datetime"
LEFT  JOIN wind_actual      wa  ON wa."DATETIME" = hf."datetime"
LEFT  JOIN solar_actual     sa  ON sa."DATETIME" = hf."datetime"

ORDER BY hf."datetime";