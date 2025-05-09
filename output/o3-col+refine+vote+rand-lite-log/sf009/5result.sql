/* -------------------------------------------------------------
   Building classification comparison: Amsterdam  vs  Rotterdam
   -------------------------------------------------------------
   • Counts unique building IDs per CLASS / SUBCLASS in each city
   • Sums their surface area in square metres
   • Ordered alphabetically by CLASS and SUBCLASS
----------------------------------------------------------------*/
WITH addr AS (   -- explode the address JSON and keep only A’dam / Rotterdam rows
    SELECT
        b."ID",
        b."CLASS",
        b."SUBCLASS",
        TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")          AS "SURF",
        LOWER(f.value:"addr:city"::STRING)            AS "CITY"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b,
         LATERAL FLATTEN( INPUT => PARSE_JSON(b."CONTAINS_ADDRESSES") ) f
    WHERE f.value:"addr:city" IS NOT NULL
      AND (LOWER(f.value:"addr:city"::STRING) LIKE '%amsterdam%'
           OR LOWER(f.value:"addr:city"::STRING) LIKE '%rotterdam%')
),
per_building AS (    -- one record per building, flagging presence in each city
    SELECT
        "ID",
        "CLASS",
        "SUBCLASS",
        "SURF",
        MAX( CASE WHEN CITY LIKE '%amsterdam%'  THEN 1 ELSE 0 END ) AS "IN_AMS",
        MAX( CASE WHEN CITY LIKE '%rotterdam%' THEN 1 ELSE 0 END ) AS "IN_ROT"
    FROM addr
    GROUP BY "ID","CLASS","SUBCLASS","SURF"
)
SELECT
    "CLASS",
    "SUBCLASS",
    COUNT_IF( "IN_AMS" = 1 )                           AS "AMSTERDAM_BUILDING_COUNT",
    SUM( CASE WHEN "IN_AMS" = 1  THEN "SURF" END )     AS "AMSTERDAM_TOTAL_SURF_SQM",
    COUNT_IF( "IN_ROT" = 1 )                           AS "ROTTERDAM_BUILDING_COUNT",
    SUM( CASE WHEN "IN_ROT" = 1 THEN "SURF" END )      AS "ROTTERDAM_TOTAL_SURF_SQM"
FROM  per_building
GROUP BY "CLASS","SUBCLASS"
ORDER BY "CLASS","SUBCLASS";