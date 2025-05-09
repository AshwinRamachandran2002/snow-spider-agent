/*--------------------------------------------------------------------
 ERCOT – Daily Market Dynamics Report
 Date Covered : 01‑Oct‑2022 (hourly)
--------------------------------------------------------------------*/
WITH hrs AS (   /* build the 24‑hour timeline & peak flags */
    SELECT
        DATEADD(hour, seq4(), '2022-10-01 00:00:00')                    AS "DATETIME",
        'CDT'                                                          AS "TIMEZONE",
        DATEADD(hour, 5, DATEADD(hour, seq4(), '2022-10-01 00:00:00')) AS "DATETIME_UTC",
        /* weekday: 0 = Sunday … 6 = Saturday in Snowflake */
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                         AS "ONPEAK",
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 0 ELSE 1 END                                         AS "OFFPEAK",
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) IN (0,6)
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                         AS "WEPEAK",
        CASE WHEN DATE_PART('dow', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 1 AND 5
               AND DATE_PART('hour', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) BETWEEN 7 AND 22
             THEN 1 ELSE 0 END                                         AS "WDPEAK",
        DATE_TRUNC('day', DATEADD(hour, seq4(), '2022-10-01 00:00:00')) AS "MARKETDAY"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/* ----------  latest‑published load forecast per hour ---------- */
load_fcst AS (
    SELECT "DATETIME", "VALUE", "PUBLISHDATE"
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM  YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
        JOIN  hrs h  ON h."DATETIME" = tf."DATETIME"
        WHERE tf."OBJECTID"   = 10000712973
          AND tf."DATATYPEID" = 19060               /* load forecast */
    )
    WHERE rn = 1
),
/* ----------  wind forecast ---------- */
wind_fcst AS (
    SELECT "DATETIME", "VALUE", "PUBLISHDATE"
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM  YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
        JOIN  hrs h  ON h."DATETIME" = tf."DATETIME"
        WHERE tf."OBJECTID"   = 10000712973
          AND tf."DATATYPEID" = 9285                /* wind forecast */
    )
    WHERE rn = 1
),
/* ----------  solar forecast ---------- */
solar_fcst AS (
    SELECT "DATETIME", "VALUE", "PUBLISHDATE"
    FROM (
        SELECT tf.*,
               ROW_NUMBER() OVER (PARTITION BY tf."DATETIME"
                                  ORDER BY tf."PUBLISHDATE" DESC) AS rn
        FROM  YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" tf
        JOIN  hrs h  ON h."DATETIME" = tf."DATETIME"
        WHERE tf."OBJECTID"   = 10000712973
          AND tf."DATATYPEID" = 662                 /* solar forecast */
    )
    WHERE rn = 1
)
/* --------------------------------------------------------------------------- */
SELECT
    'ERCOT'                                            AS "ISO",
    hrs."DATETIME",
    hrs."TIMEZONE",
    hrs."DATETIME_UTC",
    hrs."ONPEAK",
    hrs."OFFPEAK",
    hrs."WEPEAK",
    hrs."WDPEAK",
    hrs."MARKETDAY",

    pn."PNODENAME"                                     AS "PRICE_NODE_NAME",
    pn."OBJECTID"                                      AS "PRICE_NODE_ID",
    dp."DALMP",
    dp."RTLMP",

    lz."OBJECTNAME"                                    AS "LOAD_ZONE_NAME",
    lz."OBJECTID"                                      AS "LOAD_ZONE_ID",

    lf."VALUE"                                         AS "LOAD_FORECAST_MW",
    lf."PUBLISHDATE"                                   AS "LOAD_FCST_PUB_DT",

    tl."VALUE"                                         AS "RTLOAD_MW",

    wf."VALUE"                                         AS "WIND_FCST_MW",
    wf."PUBLISHDATE"                                   AS "WIND_FCST_PUB_DT",

    wa."VALUE"                                         AS "WIND_GEN_MW",

    sf."VALUE"                                         AS "SOLAR_FCST_MW",
    sf."PUBLISHDATE"                                   AS "SOLAR_FCST_PUB_DT",

    sa."VALUE"                                         AS "SOLAR_GEN_MW",

    /* ---- derived metrics ---- */
    (lf."VALUE" - COALESCE(wf."VALUE",0) - COALESCE(sf."VALUE",0))          AS "NET_LOAD_FCST_MW",
    (tl."VALUE" - COALESCE(wa."VALUE",0) - COALESCE(sa."VALUE",0))          AS "NET_LOAD_RT_MW"

FROM   hrs
/* prices (left join keeps timeline even if prices absent) */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
       ON dp."OBJECTID" = 10000697078
      AND dp."DATETIME" = hrs."DATETIME"
/* price‑node metadata */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."PRICE_NODES_SAMPLE" pn
       ON pn."OBJECTID" = 10000697078
/* load‑zone metadata */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" lz
       ON lz."OBJECTID" = 10000712973
/* forecasts */
LEFT JOIN load_fcst  lf ON lf."DATETIME" = hrs."DATETIME"
LEFT JOIN wind_fcst  wf ON wf."DATETIME" = hrs."DATETIME"
LEFT JOIN solar_fcst sf ON sf."DATETIME" = hrs."DATETIME"
/* actuals */
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE" tl
       ON tl."OBJECTID" = 10000712973
      AND tl."DATETIME" = hrs."DATETIME"
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" wa
       ON wa."OBJECTID"   = 10000712973
      AND wa."DATATYPEID" = 16                    /* wind actual */
      AND wa."DATETIME"   = hrs."DATETIME"
LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" sa
       ON sa."OBJECTID"   = 10000712973
      AND sa."DATATYPEID" = 650                   /* solar actual */
      AND sa."DATETIME"   = hrs."DATETIME"
/* presentation order */
ORDER BY hrs."DATETIME" ASC;