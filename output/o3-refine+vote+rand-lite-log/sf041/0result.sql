/*=====================================================================
 ERCOT  ‑  Daily Market‑Dynamics Report
           1 October 2022   (local ERCOT time)
=====================================================================*/
WITH
/*--------------------------------------------------------------------
1)  Build an hourly “calendar” for 1‑Oct‑2022 (local ERCOT clock)
--------------------------------------------------------------------*/
hour_dim AS (
    SELECT
        hr AS "HOUR_ENDING" ,                                   -- local HE
        CONVERT_TIMEZONE('America/Chicago', 'UTC', hr)
                 AS "HOUR_ENDING_UTC" ,
        'CDT'            AS "TIMEZONE" ,
        /* peak‑classifications */
        /* weekday number   1 = Monday … 7 = Sunday                */
        CASE
            WHEN DAYOFWEEK(hr) IN (6,7)  /* Sat / Sun */          THEN 0
            WHEN DATE_PART('hour', hr) BETWEEN 7 AND 21           THEN 1
            ELSE 0
        END                        AS "WDPEAK" ,
        CASE
            WHEN DAYOFWEEK(hr) IN (6,7)
             AND DATE_PART('hour', hr) BETWEEN 15 AND 21          THEN 1
            ELSE 0
        END                        AS "WEPEAK" ,
        /* generic on/off‑peak flags                               */
        CASE
            WHEN (  DAYOFWEEK(hr) NOT IN (6,7)
                    AND DATE_PART('hour', hr) BETWEEN 7 AND 21 )
              OR  ( DAYOFWEEK(hr) IN (6,7)
                    AND DATE_PART('hour', hr) BETWEEN 15 AND 21 )
            THEN 1 ELSE 0
        END                        AS "ONPEAK" ,
        CASE
            WHEN (  DAYOFWEEK(hr) NOT IN (6,7)
                    AND DATE_PART('hour', hr) BETWEEN 7 AND 21 )
              OR  ( DAYOFWEEK(hr) IN (6,7)
                    AND DATE_PART('hour', hr) BETWEEN 15 AND 21 )
            THEN 0 ELSE 1
        END                        AS "OFFPEAK"
    FROM (
        SELECT
            DATEADD(
                hour
              , SEQ4()
              , '2022-10-01 00:00:00'::TIMESTAMP_NTZ
            ) AS hr
        FROM TABLE(GENERATOR(ROWCOUNT => 24))
    )
),

/*--------------------------------------------------------------------
2)  Day‑Ahead & Real‑Time LMPs – price node OBJECTID 10000697078
--------------------------------------------------------------------*/
price_data AS (
    SELECT
        dp."DATETIME"        AS "HOUR_ENDING",
        dp."DALMP" ,
        dp."RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
    WHERE dp."OBJECTID" = 10000697078
      AND DATE(dp."DATETIME") = '2022-10-01'
),

/*--------------------------------------------------------------------
3)  Load – forecast (datatype 19060) & actual RT load
--------------------------------------------------------------------*/
load_forecast AS (
    SELECT
        lf."DATETIME"                     AS "HOUR_ENDING",
        lf."VALUE"                        AS "LOAD_FORECAST",
        lf."PUBLISHDATE"                  AS "LOAD_FORECAST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" lf
    WHERE lf."OBJECTID"   = 10000712973
      AND lf."DATATYPEID" = 19060
      AND DATE(lf."DATETIME") = '2022-10-01'
),
load_actual AS (
    SELECT
        DATE_TRUNC('HOUR', rl."DATETIME") AS "HOUR_ENDING",
        AVG(rl."LOAD")                    AS "RTLOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."RT_LOADS_SAMPLE" rl
    WHERE rl."OBJECTID" = 10000712973
      AND DATE(rl."DATETIME") = '2022-10-01'
    GROUP BY 1
),

/*--------------------------------------------------------------------
4)  Wind generation – forecast (9285) & actual (16)
--------------------------------------------------------------------*/
wind_forecast AS (
    SELECT
        wf."DATETIME"      AS "HOUR_ENDING",
        wf."VALUE"         AS "WIND_GEN_FORECAST",
        wf."PUBLISHDATE"   AS "WIND_FORECAST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" wf
    WHERE wf."OBJECTID"   = 10000712973
      AND wf."DATATYPEID" = 9285
      AND DATE(wf."DATETIME") = '2022-10-01'
),
wind_actual AS (
    SELECT
        DATE_TRUNC('HOUR', wa."DATETIME") AS "HOUR_ENDING",
        AVG(wa."VALUE")                   AS "WIND_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" wa
    WHERE wa."OBJECTID"   = 10000712973
      AND wa."DATATYPEID" = 16
      AND DATE(wa."DATETIME") = '2022-10-01'
    GROUP BY 1
),

/*--------------------------------------------------------------------
5)  Solar generation – forecast (662) & actual (650)
--------------------------------------------------------------------*/
solar_forecast AS (
    SELECT
        sf."DATETIME"      AS "HOUR_ENDING",
        sf."VALUE"         AS "SOLAR_GEN_FORECAST",
        sf."PUBLISHDATE"   AS "SOLAR_FORECAST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" sf
    WHERE sf."OBJECTID"   = 10000712973
      AND sf."DATATYPEID" = 662
      AND DATE(sf."DATETIME") = '2022-10-01'
),
solar_actual AS (
    SELECT
        DATE_TRUNC('HOUR', sa."DATETIME") AS "HOUR_ENDING",
        AVG(sa."VALUE")                   AS "SOLAR_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" sa
    WHERE sa."OBJECTID"   = 10000712973
      AND sa."DATATYPEID" = 650
      AND DATE(sa."DATETIME") = '2022-10-01'
    GROUP BY 1
)

/*--------------------------------------------------------------------
6)  Assemble final report
--------------------------------------------------------------------*/
SELECT
    h."HOUR_ENDING"          ,
    h."HOUR_ENDING_UTC"      ,
    h."TIMEZONE"             ,
    h."ONPEAK" ,
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",

    p."DALMP" ,
    p."RTLMP" ,

    lf."LOAD_FORECAST"              ,
    lf."LOAD_FORECAST_PUBLISH_DATE" ,
    la."RTLOAD"                     ,

    wf."WIND_GEN_FORECAST"          ,
    wf."WIND_FORECAST_PUBLISH_DATE" ,
    wa."WIND_GEN"                   ,

    sf."SOLAR_GEN_FORECAST"         ,
    sf."SOLAR_FORECAST_PUBLISH_DATE",
    sa."SOLAR_GEN"                  ,

    /* Net‑load metrics */
    ( lf."LOAD_FORECAST"
      - COALESCE(wf."WIND_GEN_FORECAST",0)
      - COALESCE(sf."SOLAR_GEN_FORECAST",0)
    ) AS "NET_LOAD_FORECAST" ,

    ( la."RTLOAD"
      - COALESCE(wa."WIND_GEN",0)
      - COALESCE(sa."SOLAR_GEN",0)
    ) AS "NET_LOAD_REAL_TIME"

FROM hour_dim             h
LEFT JOIN price_data      p  ON p."HOUR_ENDING"   = h."HOUR_ENDING"
LEFT JOIN load_forecast   lf ON lf."HOUR_ENDING"  = h."HOUR_ENDING"
LEFT JOIN load_actual     la ON la."HOUR_ENDING"  = h."HOUR_ENDING"
LEFT JOIN wind_forecast   wf ON wf."HOUR_ENDING"  = h."HOUR_ENDING"
LEFT JOIN wind_actual     wa ON wa."HOUR_ENDING"  = h."HOUR_ENDING"
LEFT JOIN solar_forecast  sf ON sf."HOUR_ENDING"  = h."HOUR_ENDING"
LEFT JOIN solar_actual    sa ON sa."HOUR_ENDING"  = h."HOUR_ENDING"

ORDER BY h."HOUR_ENDING";