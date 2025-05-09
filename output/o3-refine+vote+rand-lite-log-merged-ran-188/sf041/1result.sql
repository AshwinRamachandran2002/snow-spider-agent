/*  ERCOT market-dynamics sample report – any dates with available data  */

SELECT
       p."DATETIME",                                            
       COALESCE(im."TIMEZONE", p."TIMEZONE")      AS "TIMEZONE",
       p."DALMP"                                  AS "DA_LMP_$MWH",
       p."RTLMP"                                  AS "RT_LMP_$MWH",

       lf."VALUE"                                 AS "LOAD_FORECAST_MW",
       la."VALUE"                                 AS "RT_LOAD_MW",

       wf."VALUE"                                 AS "WIND_FORECAST_MW",
       wa."VALUE"                                 AS "WIND_ACTUAL_MW",

       sf."VALUE"                                 AS "SOLAR_FORECAST_MW",
       sa."VALUE"                                 AS "SOLAR_ACTUAL_MW",

       im."ONPEAK",
       im."OFFPEAK",
       im."WEPEAK",
       im."WDPEAK",

       /*  calculated net-load metrics  */
       (lf."VALUE" - COALESCE(wf."VALUE",0) - COALESCE(sf."VALUE",0)) AS "NET_LOAD_FORECAST_MW",
       (la."VALUE" - COALESCE(wa."VALUE",0) - COALESCE(sa."VALUE",0)) AS "NET_LOAD_REALTIME_MW"

FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"  p

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"  lf
       ON lf."OBJECTID" = 10000712973
      AND lf."DATATYPEID" = 19060          -- load forecast
      AND lf."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"      la
       ON la."OBJECTID"   = 10000712973
      AND la."DATATYPEID" = 9641           -- actual load
      AND la."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"  wf
       ON wf."OBJECTID"   = 10000712973
      AND wf."DATATYPEID" = 9285           -- wind forecast
      AND wf."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"       wa
       ON wa."OBJECTID"   = 10000712973
      AND wa."DATATYPEID" = 16             -- wind actual
      AND wa."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"  sf
       ON sf."OBJECTID"   = 10000712973
      AND sf."DATATYPEID" = 662            -- solar forecast
      AND sf."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"       sa
       ON sa."OBJECTID"   = 10000712973
      AND sa."DATATYPEID" = 650            -- solar actual
      AND sa."DATETIME"   = p."DATETIME"

LEFT   JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" im
       ON im."ISO"      = 'ERCOT'
      AND im."DATETIME" = p."DATETIME"

WHERE  p."OBJECTID" = 10000697078      -- HB_NORTH price node

ORDER  BY p."DATETIME"
LIMIT  100;