/*---------------------------------------------------------------
  Building-classification comparison between Amsterdam & Rotterdam
----------------------------------------------------------------*/
WITH relevant_buildings AS (   -- 1. pick buildings that belong to either city
    SELECT  DISTINCT                -- DISTINCT keeps every building only once,
            b."ID",
            b."CLASS",
            b."SUBCLASS",
            TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")  AS "SURF_SQ_M",
            CASE
                 WHEN addr.value:"addr:city"::STRING ILIKE '%amsterdam%'  THEN 'Amsterdam'
                 WHEN addr.value:"addr:city"::STRING ILIKE '%rotterdam%'  THEN 'Rotterdam'
            END                                                        AS "CITY"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"  b,
           LATERAL FLATTEN( INPUT => PARSE_JSON(b."CONTAINS_ADDRESSES") ) addr
    WHERE  addr.value:"addr:city" IS NOT NULL
      AND (   addr.value:"addr:city"::STRING ILIKE '%amsterdam%'
           OR addr.value:"addr:city"::STRING ILIKE '%rotterdam%' )
),
city_aggregates AS (            -- 2. aggregate per city / class / subclass
    SELECT  "CITY",
            "CLASS",
            "SUBCLASS",
            COUNT(*)                         AS "BUILDING_CNT",
            SUM("SURF_SQ_M")                 AS "TOTAL_SURF_SQ_M"
    FROM    relevant_buildings
    GROUP BY "CITY","CLASS","SUBCLASS"
)

/*---------------------------------------------------------------
  3. pivot Amsterdam & Rotterdam figures side-by-side
----------------------------------------------------------------*/
SELECT
    COALESCE(am."CLASS", rt."CLASS")                       AS "CLASS",
    COALESCE(am."SUBCLASS", rt."SUBCLASS")                 AS "SUBCLASS",

    am."BUILDING_CNT"          AS "AMSTERDAM_BUILDING_CNT",
    am."TOTAL_SURF_SQ_M"       AS "AMSTERDAM_TOTAL_SURF_SQ_M",

    rt."BUILDING_CNT"          AS "ROTTERDAM_BUILDING_CNT",
    rt."TOTAL_SURF_SQ_M"       AS "ROTTERDAM_TOTAL_SURF_SQ_M"

FROM   (SELECT * FROM city_aggregates WHERE "CITY" = 'Amsterdam')  am
FULL   OUTER JOIN
       (SELECT * FROM city_aggregates WHERE "CITY" = 'Rotterdam')  rt
       ON  am."CLASS"    = rt."CLASS"
       AND am."SUBCLASS" = rt."SUBCLASS"

ORDER BY
       COALESCE(am."CLASS", rt."CLASS"),
       COALESCE(am."SUBCLASS", rt."SUBCLASS");