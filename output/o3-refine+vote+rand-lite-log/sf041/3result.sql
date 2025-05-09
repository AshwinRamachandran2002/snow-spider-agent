/*-----------------------------------------------------------------------
 ERCOT • Daily Market‑Dynamics Report • 1‑Oct‑2022
  – Hourly DA / RT prices (NODE 10000697078)
  – Load, wind, solar  •  forecast vs. actual
  – Peak‑class flags • UTC time • Net‑load metrics
------------------------------------------------------------------------*/
WITH timeline AS (          /* build 24 hourly stamps for 2022‑10‑01 (CDT) */
    SELECT
        dt                              AS "DATETIME",
        'CDT'                           AS "TIMEZONE",              /* DST */
        CONVERT_TIMEZONE('America/Chicago','UTC',dt) AS "DATETIME_UTC",
        /* ---- peak classifications ------------------------------------ */
        CASE
             WHEN DAYOFWEEKISO(dt) BETWEEN 1 AND 5  /* Mon‑Fri */
              AND DATE_PART('hour',dt) BETWEEN 7 AND 21 THEN 1 ELSE 0
        END                            AS "ONPEAK",
        CASE
             WHEN DAYOFWEEKISO(dt) BETWEEN 1 AND 5
              AND DATE_PART('hour',dt) BETWEEN 7 AND 21 THEN 0 ELSE 1
        END                            AS "OFFPEAK",
        CASE
             WHEN DAYOFWEEKISO(dt) IN (6,7)         /* Sat‑Sun */
              AND DATE_PART('hour',dt) BETWEEN 7 AND 21 THEN 1 ELSE 0
        END                            AS "WEPEAK",
        CASE
             WHEN DAYOFWEEKISO(dt) BETWEEN 1 AND 5
              AND DATE_PART('hour',dt) BETWEEN 7 AND 21 THEN 1 ELSE 0
        END                            AS "WDPEAK"
    FROM (
        SELECT DATEADD(hour, seq4(),
                       '2022-10-01 00:00:00'::timestamp) AS dt
        FROM TABLE(GENERATOR(ROWCOUNT => 24))
    )
),
/* ---------------- prices --------------------------------------------- */
prices AS (
    SELECT  "DATETIME",
            "DALMP",
            "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.DART_PRICES_SAMPLE
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2022-10-01'
),
/* ---------------- forecasts : keep latest vintage per hour ------------ */
load_forecast AS (
    SELECT "DATETIME","VALUE" AS "LOAD_FORECAST","PUBLISHDATE"
    FROM (
        SELECT  "DATETIME","VALUE","PUBLISHDATE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "DATATYPEID" = 19060
          AND "OBJECTID"   = 10000712973
          AND DATE("DATETIME") = '2022-10-01'
    ) WHERE rn = 1
),
wind_forecast AS (
    SELECT "DATETIME","VALUE" AS "WIND_FORECAST","PUBLISHDATE"
    FROM (
        SELECT  "DATETIME","VALUE","PUBLISHDATE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "DATATYPEID" = 9285
          AND "OBJECTID"   = 10000712973
          AND DATE("DATETIME") = '2022-10-01'
    ) WHERE rn = 1
),
solar_forecast AS (
    SELECT "DATETIME","VALUE" AS "SOLAR_FORECAST","PUBLISHDATE"
    FROM (
        SELECT  "DATETIME","VALUE","PUBLISHDATE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "DATATYPEID" = 662
          AND "OBJECTID"   = 10000712973
          AND DATE("DATETIME") = '2022-10-01'
    ) WHERE rn = 1
),
/* ---------------- actuals aggregated to top of hour ------------------- */
actual_load AS (
    SELECT DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
           AVG("LOAD")                   AS "ACTUAL_LOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.RT_LOADS_SAMPLE
    WHERE "OBJECTID" = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),
actual_wind AS (
    SELECT DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
           AVG("VALUE")                  AS "ACTUAL_WIND"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "DATATYPEID" = 16                 /* wind actual */
      AND "OBJECTID"   = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),
actual_solar AS (
    SELECT DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
           AVG("VALUE")                  AS "ACTUAL_SOLAR"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "DATATYPEID" = 650                /* solar actual */
      AND "OBJECTID"   = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
)
/* =========================  final report  ============================== */
SELECT
    t."DATETIME"                       AS "datetime_local",
    t."TIMEZONE",
    t."DATETIME_UTC",
    t."ONPEAK",
    t."OFFPEAK",
    t."WEPEAK",
    t."WDPEAK",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST",
    lf."PUBLISHDATE"                   AS "load_fc_publish_date",
    al."ACTUAL_LOAD"                   AS "rtload",
    wf."WIND_FORECAST",
    wf."PUBLISHDATE"                   AS "wind_fc_publish_date",
    aw."ACTUAL_WIND"                   AS "wind_gen",
    sf."SOLAR_FORECAST",
    sf."PUBLISHDATE"                   AS "solar_fc_publish_date",
    asr."ACTUAL_SOLAR"                 AS "solar_gen",
    /* ---------------- net‑load metrics --------------------------------- */
    (lf."LOAD_FORECAST"
        - COALESCE(wf."WIND_FORECAST",0)
        - COALESCE(sf."SOLAR_FORECAST",0))  AS "net_load_forecast",
    (al."ACTUAL_LOAD"
        - COALESCE(aw."ACTUAL_WIND",0)
        - COALESCE(asr."ACTUAL_SOLAR",0))   AS "net_load_real_time"
FROM   timeline             t
LEFT JOIN prices            p   ON p."DATETIME" = t."DATETIME"
LEFT JOIN load_forecast     lf  ON lf."DATETIME" = t."DATETIME"
LEFT JOIN wind_forecast     wf  ON wf."DATETIME" = t."DATETIME"
LEFT JOIN solar_forecast    sf  ON sf."DATETIME" = t."DATETIME"
LEFT JOIN actual_load       al  ON al."DATETIME" = t."DATETIME"
LEFT JOIN actual_wind       aw  ON aw."DATETIME" = t."DATETIME"
LEFT JOIN actual_solar      asr ON asr."DATETIME" = t."DATETIME"
ORDER BY t."DATETIME" ASC;