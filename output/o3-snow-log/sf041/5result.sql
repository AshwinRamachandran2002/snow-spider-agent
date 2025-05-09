/*---------------------------------------------------------------*/
/*  ERCOT Daily Market Dynamics Report – October 1 2022          */
/*  “Hours” are generated directly (00-23 CDT) so results exist  */
/*  even if reference tables lack rows for the same date.        */
/*---------------------------------------------------------------*/

WITH
/* 1) Generate the 24 local hours for 2022-10-01 (still CDT)  */
hours AS (
    SELECT
        DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00')) AS "DATETIME",
        'CDT'                                                         AS "TIMEZONE",
        /* simple peak logic: weekday HE 07-22 = on-peak              */
        CASE
            WHEN DAYOFWEEK(DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 2 AND 6
             AND EXTRACT(hour FROM DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 7 AND 22
                THEN 1 ELSE 0 END                                     AS "ONPEAK",
        CASE
            WHEN DAYOFWEEK(DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 2 AND 6
             AND EXTRACT(hour FROM DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 7 AND 22
                THEN 0 ELSE 1 END                                     AS "OFFPEAK",
        /* weekend-peak (15-22)                                        */
        CASE
            WHEN DAYOFWEEK(DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) IN (1,7)
             AND EXTRACT(hour FROM DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 15 AND 22
                THEN 1 ELSE 0 END                                     AS "WEPEAK",
        /* weekday-peak mirrors ONPEAK                                 */
        CASE
            WHEN DAYOFWEEK(DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 2 AND 6
             AND EXTRACT(hour FROM DATEADD(hour, seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))) BETWEEN 7 AND 22
                THEN 1 ELSE 0 END                                     AS "WDPEAK"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* 2) Day-ahead & real-time LMPs for price-node 10000697078     */
prices AS (
    SELECT
        "DATETIME",
        "DALMP"::NUMBER AS "DALMP",
        "RTLMP"::NUMBER AS "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.DART_PRICES_SAMPLE
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2022-10-01'
),

/* 3) Hourly-average real-time load (actual) for zone 10000712973 */
rt_load AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        AVG("LOAD"::NUMBER)           AS "RTLOAD_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.RT_LOADS_SAMPLE
    WHERE "OBJECTID" = 10000712973
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),

/* 4) Latest-published hourly load forecast (datatype 19060)     */
load_fc AS (
    SELECT  "DATETIME",
            "VALUE"::NUMBER AS "LOAD_FORECAST_MW"
    FROM (
        SELECT  "DATETIME",
                "VALUE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 19060
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),

/* 5) Latest-published hourly wind forecast (datatype 9285)      */
wind_fc AS (
    SELECT  "DATETIME",
            "VALUE"::NUMBER AS "WIND_FORECAST_MW"
    FROM (
        SELECT  "DATETIME",
                "VALUE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 9285
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),

/* 6) Latest-published hourly solar forecast (datatype 662)      */
solar_fc AS (
    SELECT  "DATETIME",
            "VALUE"::NUMBER AS "SOLAR_FORECAST_MW"
    FROM (
        SELECT  "DATETIME",
                "VALUE",
                ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                   ORDER BY "PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
        WHERE "OBJECTID"   = 10000712973
          AND "DATATYPEID" = 662
          AND DATE("DATETIME") = '2022-10-01'
    )
    WHERE rn = 1
),

/* 7) Hourly-average actual wind generation (datatype 16)        */
wind_act AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        AVG("VALUE"::NUMBER)          AS "WIND_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
),

/* 8) Hourly-average actual solar generation (datatype 650)      */
solar_act AS (
    SELECT
        DATE_TRUNC('hour',"DATETIME") AS "DATETIME",
        AVG("VALUE"::NUMBER)          AS "SOLAR_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND DATE("DATETIME") = '2022-10-01'
    GROUP BY 1
)

/*---------------------------------------------------------------*/
/* 9)  Assemble final report                                     */
SELECT
    h."DATETIME",
    h."TIMEZONE",
    h."ONPEAK",
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",
    pr."DALMP"                        AS "DALMP_$/MWh",
    pr."RTLMP"                        AS "RTLMP_$/MWh",
    lf."LOAD_FORECAST_MW",
    rl."RTLOAD_MW"                    AS "LOAD_ACTUAL_MW",
    wf."WIND_FORECAST_MW",
    wa."WIND_ACTUAL_MW",
    sf."SOLAR_FORECAST_MW",
    sa."SOLAR_ACTUAL_MW",
    /* Net-load forecasts & real-time                             */
    CASE 
        WHEN lf."LOAD_FORECAST_MW" IS NULL THEN NULL
        ELSE lf."LOAD_FORECAST_MW"
             - COALESCE(wf."WIND_FORECAST_MW",0)
             - COALESCE(sf."SOLAR_FORECAST_MW",0)
    END                               AS "NET_LOAD_FORECAST_MW",
    CASE
        WHEN rl."RTLOAD_MW" IS NULL THEN NULL
        ELSE rl."RTLOAD_MW"
             - COALESCE(wa."WIND_ACTUAL_MW",0)
             - COALESCE(sa."SOLAR_ACTUAL_MW",0)
    END                               AS "NET_LOAD_RT_MW"
FROM               hours      h
LEFT JOIN          prices     pr ON pr."DATETIME" = h."DATETIME"
LEFT JOIN          load_fc    lf ON lf."DATETIME" = h."DATETIME"
LEFT JOIN          rt_load    rl ON rl."DATETIME" = h."DATETIME"
LEFT JOIN          wind_fc    wf ON wf."DATETIME" = h."DATETIME"
LEFT JOIN          wind_act   wa ON wa."DATETIME" = h."DATETIME"
LEFT JOIN          solar_fc   sf ON sf."DATETIME" = h."DATETIME"
LEFT JOIN          solar_act  sa ON sa."DATETIME" = h."DATETIME"
ORDER BY h."DATETIME";