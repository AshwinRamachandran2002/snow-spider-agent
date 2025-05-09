WITH building_city AS (
    /*------------------------------------------------------------------*/
    /* 1. Unnest address array, retain Amsterdam & Rotterdam addresses   */
    /*------------------------------------------------------------------*/
    SELECT
        b."ID",
        b."CLASS",
        b."SUBCLASS",
        LOWER(TRIM(addr.value:"addr:city"::string))                AS "CITY",
        TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")                       AS "SURFACE_AREA_SQ_M",
        ROW_NUMBER() OVER (PARTITION BY b."ID" ORDER BY addr.index) AS "RN"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"  b,
         LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(b."CONTAINS_ADDRESSES")) addr
    WHERE addr.value:"addr:city" IS NOT NULL
      AND LOWER(TRIM(addr.value:"addr:city"::string)) IN ('amsterdam', 'rotterdam')
),
filtered AS (
    /*------------------------------------------------------------------*/
    /* 2. Keep only one address record per building (RN = 1)            */
    /*------------------------------------------------------------------*/
    SELECT
        "ID",
        "CLASS",
        "SUBCLASS",
        "CITY",
        "SURFACE_AREA_SQ_M"
    FROM building_city
    WHERE "RN" = 1
)
SELECT
    /*------------------------------------------------------------------*/
    /* 3. Side‑by‑side comparison for Amsterdam vs. Rotterdam           */
    /*------------------------------------------------------------------*/
    "CLASS",
    "SUBCLASS",
    /* Amsterdam metrics */
    SUM(CASE WHEN "CITY" = 'amsterdam' THEN "SURFACE_AREA_SQ_M" ELSE 0 END) AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    SUM(CASE WHEN "CITY" = 'amsterdam' THEN 1                     ELSE 0 END) AS "AMSTERDAM_TOTAL_BUILDINGS",
    /* Rotterdam metrics */
    SUM(CASE WHEN "CITY" = 'rotterdam' THEN "SURFACE_AREA_SQ_M" ELSE 0 END) AS "ROTTERDAM_TOTAL_SURFACE_SQ_M",
    SUM(CASE WHEN "CITY" = 'rotterdam' THEN 1                     ELSE 0 END) AS "ROTTERDAM_TOTAL_BUILDINGS"
FROM filtered
GROUP BY "CLASS", "SUBCLASS"
ORDER BY "CLASS" ASC,
         "SUBCLASS" ASC;