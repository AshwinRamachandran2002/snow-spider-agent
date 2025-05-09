/*--------------------------------------------------------------------
 ERCOT – Daily Market‑Dynamics Report
 Data window:  1 October 2022  (local ERCOT clock)
--------------------------------------------------------------------*/
WITH
/*------------------------------------------------------------------*/
hrs AS (                     -- build the 24 local hours for 01‑Oct‑2022
    SELECT
        DATEADD(hour, seq4(), '2022-10-01 00:00:00') AS "datetime"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
hrs_class AS (               -- add time‑zone and simple peak flags
    SELECT
        h."datetime",
        'CDT'                                                     AS "timezone",
        CONVERT_TIMEZONE('America/Chicago','UTC', h."datetime")   AS "datetime_utc",
        /* simple classification rules -------------------------- */
        0                                                         AS "ONPEAK",              -- not used for this day
        CASE WHEN HOUR(h."datetime") NOT BETWEEN 7 AND 22 THEN 1 ELSE 0 END  AS "OFFPEAK",
        CASE WHEN DAYOFWEEKISO(h."datetime") IN (6,7)
                  AND HOUR(h."datetime") BETWEEN 7 AND 22 THEN 1 ELSE 0 END  AS "WEPEAK",
        CASE WHEN DAYOFWEEKISO(h."datetime") BETWEEN 1 AND 5
                  AND HOUR(h."datetime") BETWEEN 7 AND 22 THEN 1 ELSE 0 END  AS "WDPEAK"
    FROM hrs h
),
/*------------------------------------------------------------------*/
price AS (                    -- Day‑Ahead / Real‑Time LMPs  (HB_NORTH)
    SELECT
        "DATETIME",
        "DALMP",
        "RTLMP"
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2022-10-01'
),
/*------------------------------------------------------------------*/
load_fcst AS (                -- latest hourly load forecast (datatype 19060)
    SELECT "DATETIME",
           "VALUE"       AS load_forecast,
           "PUBLISHDATE" AS load_fcst_publish_date
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE" tf
        WHERE tf."OBJECTID"  = 10000712973
          AND tf."DATATYPEID" = 19060
          AND DATE(tf."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
/*------------------------------------------------------------------*/
load_act AS (                 -- hourly actual load
    SELECT "DATETIME",
           "VALUE" AS rtload
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE "OBJECTID" = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
),
/*------------------------------------------------------------------*/
wind_fcst AS (                -- latest wind‑generation forecast (datatype 9285)
    SELECT "DATETIME",
           "VALUE"       AS wind_fcst,
           "PUBLISHDATE" AS wind_fcst_publish_date
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE" tf
        WHERE tf."OBJECTID"  = 10000712973
          AND tf."DATATYPEID" = 9285
          AND DATE(tf."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
/*------------------------------------------------------------------*/
solar_fcst AS (               -- latest solar‑generation forecast (datatype 662)
    SELECT "DATETIME",
           "VALUE"       AS solar_fcst,
           "PUBLISHDATE" AS solar_fcst_publish_date
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE" tf
        WHERE tf."OBJECTID"  = 10000712973
          AND tf."DATATYPEID" = 662
          AND DATE(tf."DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),
/*------------------------------------------------------------------*/
wind_act AS (                 -- hourly actual wind generation (datatype 16)
    SELECT "DATETIME",
           "VALUE" AS wind_gen
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"  = 10000712973
      AND "DATATYPEID" = 16
      AND DATE("DATETIME") = '2022-10-01'
),
/*------------------------------------------------------------------*/
solar_act AS (                -- hourly actual solar generation (datatype 650)
    SELECT "DATETIME",
           "VALUE" AS solar_gen
    FROM "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"  = 10000712973
      AND "DATATYPEID" = 650
      AND DATE("DATETIME") = '2022-10-01'
)
/*------------------------------------------------------------------*/
SELECT
    h."datetime",
    h."timezone",
    h."datetime_utc",
    h."ONPEAK",
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",
    p."DALMP"                                   AS dalmp,
    p."RTLMP"                                   AS rtlmp,
    lf.load_forecast,
    lf.load_fcst_publish_date,
    la.rtload,
    wf.wind_fcst,
    wf.wind_fcst_publish_date,
    wa.wind_gen,
    sf.solar_fcst,
    sf.solar_fcst_publish_date,
    sa.solar_gen,
    /* ------------------- derived metrics ----------------------- */
    COALESCE(lf.load_forecast ,0)
      - (COALESCE(wf.wind_fcst ,0) + COALESCE(sf.solar_fcst ,0))  AS net_load_forecast,
    COALESCE(la.rtload ,0)
      - (COALESCE(wa.wind_gen ,0) + COALESCE(sa.solar_gen ,0))    AS net_load_real_time
FROM         hrs_class        h
LEFT JOIN    price            p  ON p."DATETIME" = h."datetime"
LEFT JOIN    load_fcst        lf ON lf."DATETIME" = h."datetime"
LEFT JOIN    load_act         la ON la."DATETIME" = h."datetime"
LEFT JOIN    wind_fcst        wf ON wf."DATETIME" = h."datetime"
LEFT JOIN    wind_act         wa ON wa."DATETIME" = h."datetime"
LEFT JOIN    solar_fcst       sf ON sf."DATETIME" = h."datetime"
LEFT JOIN    solar_act        sa ON sa."DATETIME" = h."datetime"
ORDER BY h."datetime";