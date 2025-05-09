/*  ERCOT – Daily Market-Dynamics Report
    Target date: 01-Oct-2022 (local ERCOT time)      */

WITH hours AS (   -- create the 24 hourly time-stamps for the target day
    SELECT DATEADD(hour, seq4(), 
                   TO_TIMESTAMP_NTZ('2022-10-01 00:00:00'))  AS hr_local
    FROM   TABLE(GENERATOR(ROWCOUNT => 24))
),                                       
prices AS (      -- Day-Ahead & Real-Time LMPs (price-node OBJECTID 10000697078)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            MAX("DALMP"::NUMBER)               AS DALMP_MWH,
            MAX("RTLMP"::NUMBER)               AS RTLMP_MWH
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE   "OBJECTID" = 10000697078
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
load_forecast AS (      -- system load forecast (datatypeid 19060, all objects)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            SUM("VALUE"::NUMBER)               AS LOAD_FORECAST_MW,
            MAX("PUBLISHDATE")                 AS LOAD_FCST_PUBLISH
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE   "DATATYPEID" = 19060
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
rt_load AS (            -- actual real-time load (OBJECTID 10000712973)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            AVG("LOAD"::NUMBER)                AS RTLOAD_MW
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."RT_LOADS_SAMPLE"
    WHERE   "OBJECTID" = 10000712973
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
wind_forecast AS (      -- wind generation forecast (datatypeid 9285)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            AVG("VALUE"::NUMBER)               AS WIND_FORECAST_MW,
            MAX("PUBLISHDATE")                 AS WIND_FCST_PUBLISH
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE   "DATATYPEID" = 9285
      AND   "OBJECTID"  = 10000712973
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
solar_forecast AS (     -- solar generation forecast (datatypeid 662)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            AVG("VALUE"::NUMBER)               AS SOLAR_FORECAST_MW,
            MAX("PUBLISHDATE")                 AS SOLAR_FCST_PUBLISH
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE   "DATATYPEID" = 662
      AND   "OBJECTID"  = 10000712973
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
wind_gen AS (           -- actual wind generation (datatypeid 16)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            AVG("VALUE"::NUMBER)               AS WIND_GEN_MW
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE   "DATATYPEID" = 16
      AND   "OBJECTID"  = 10000712973
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
),
solar_gen AS (          -- actual solar generation (datatypeid 650)
    SELECT  DATE_TRUNC('hour',"DATETIME")      AS hr_local,
            AVG("VALUE"::NUMBER)               AS SOLAR_GEN_MW
    FROM    "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE   "DATATYPEID" = 650
      AND   "OBJECTID"  = 10000712973
      AND   DATE("DATETIME") = '2022-10-01'
    GROUP BY hr_local
)

SELECT
       h.hr_local                                         AS "HOUR_BEGIN_LOCAL",
       'CPT'                                              AS "TZ",          -- Central Prevailing Time
       CONVERT_TIMEZONE('America/Chicago','UTC',h.hr_local) 
                                                         AS "HOUR_BEGIN_UTC",
       p.DALMP_MWH                                        AS "DALMP_$MWh",
       p.RTLMP_MWH                                        AS "RTLMP_$MWh",
       lf.LOAD_FORECAST_MW,
       lf.LOAD_FCST_PUBLISH,
       rl.RTLOAD_MW,
       wf.WIND_FORECAST_MW,
       wf.WIND_FCST_PUBLISH,
       wg.WIND_GEN_MW,
       sf.SOLAR_FORECAST_MW,
       sf.SOLAR_FCST_PUBLISH,
       sg.SOLAR_GEN_MW,
       (lf.LOAD_FORECAST_MW 
          - COALESCE(wf.WIND_FORECAST_MW,0)
          - COALESCE(sf.SOLAR_FORECAST_MW,0))             AS NET_LOAD_FORECAST_MW,
       (rl.RTLOAD_MW 
          - COALESCE(wg.WIND_GEN_MW,0)
          - COALESCE(sg.SOLAR_GEN_MW,0))                  AS NET_LOAD_RT_MW,
       /* peak classifications using simple ERCOT convention:
          Weekday 07–22 = WDPEAK/ONPEAK; weekend  = WEPEAK */
       CASE 
            WHEN DAYOFWEEKISO(h.hr_local) BETWEEN 1 AND 5 
                 AND HOUR(h.hr_local) BETWEEN 7 AND 22 THEN 1 ELSE 0 
       END                                                AS "WDPEAK",
       CASE 
            WHEN DAYOFWEEKISO(h.hr_local) IN (6,7) 
                 AND HOUR(h.hr_local) BETWEEN 15 AND 22 THEN 1 ELSE 0 
       END                                                AS "WEPEAK",
       CASE 
            WHEN (DAYOFWEEKISO(h.hr_local) BETWEEN 1 AND 5 
                  AND HOUR(h.hr_local) BETWEEN 7 AND 22)
              OR (DAYOFWEEKISO(h.hr_local) IN (6,7) 
                  AND HOUR(h.hr_local) BETWEEN 15 AND 22) THEN 1 ELSE 0 
       END                                                AS "ONPEAK",
       CASE 
            WHEN (DAYOFWEEKISO(h.hr_local) BETWEEN 1 AND 5 
                  AND HOUR(h.hr_local) BETWEEN 7 AND 22)
              OR (DAYOFWEEKISO(h.hr_local) IN (6,7) 
                  AND HOUR(h.hr_local) BETWEEN 15 AND 22) THEN 0 ELSE 1 
       END                                                AS "OFFPEAK"
FROM   hours                 h
LEFT   JOIN prices           p  ON p.hr_local = h.hr_local
LEFT   JOIN load_forecast    lf ON lf.hr_local = h.hr_local
LEFT   JOIN rt_load          rl ON rl.hr_local = h.hr_local
LEFT   JOIN wind_forecast    wf ON wf.hr_local = h.hr_local
LEFT   JOIN solar_forecast   sf ON sf.hr_local = h.hr_local
LEFT   JOIN wind_gen         wg ON wg.hr_local = h.hr_local
LEFT   JOIN solar_gen        sg ON sg.hr_local = h.hr_local
ORDER BY h.hr_local;