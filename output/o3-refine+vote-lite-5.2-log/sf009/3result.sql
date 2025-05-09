WITH BUILDINGS AS (      /* extract city, class, subclass, and surface area */
    SELECT
        LOWER(
            PARSE_JSON("CONTAINS_ADDRESSES")[0]:"addr:city"::STRING
        )                                   AS CITY_LOWER,
        "CLASS",
        "SUBCLASS",
        TRY_TO_DOUBLE("SURFACE_AREA_SQ_M")  AS SURFACE_M2
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
),

CITY_FILTERED AS (       /* keep only Amsterdam & Rotterdam */
    SELECT
        "CLASS",
        "SUBCLASS",
        CASE 
            WHEN CITY_LOWER = 'amsterdam' THEN 'Amsterdam'
            WHEN CITY_LOWER = 'rotterdam' THEN 'Rotterdam'
        END                             AS CITY,
        SURFACE_M2
    FROM BUILDINGS
    WHERE CITY_LOWER IN ('amsterdam','rotterdam')
),

AGGREGATED AS (          /* aggregate per class / subclass / city */
    SELECT
        "CLASS",
        "SUBCLASS",
        CITY,
        COUNT(*)              AS BUILDING_COUNT,
        SUM(SURFACE_M2)       AS TOTAL_SURFACE_M2
    FROM CITY_FILTERED
    GROUP BY "CLASS", "SUBCLASS", CITY
),

ALL_CLASSES AS (         /* ensure every class/subclass appears even if missing in a city */
    SELECT DISTINCT "CLASS", "SUBCLASS"
    FROM AGGREGATED
)

SELECT
    ac."CLASS",
    ac."SUBCLASS",
    /* Amsterdam statistics */
    COALESCE(ROUND(am.TOTAL_SURFACE_M2, 4), 0)  AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    COALESCE(am.BUILDING_COUNT, 0)              AS "AMSTERDAM_BUILDING_COUNT",
    /* Rotterdam statistics */
    COALESCE(ROUND(rt.TOTAL_SURFACE_M2, 4), 0)  AS "ROTTERDAM_TOTAL_SURFACE_SQ_M",
    COALESCE(rt.BUILDING_COUNT, 0)              AS "ROTTERDAM_BUILDING_COUNT"
FROM ALL_CLASSES ac
LEFT JOIN AGGREGATED am
       ON ac."CLASS" = am."CLASS"
      AND ac."SUBCLASS" = am."SUBCLASS"
      AND am.CITY = 'Amsterdam'
LEFT JOIN AGGREGATED rt
       ON ac."CLASS" = rt."CLASS"
      AND ac."SUBCLASS" = rt."SUBCLASS"
      AND rt.CITY = 'Rotterdam'
ORDER BY
    ac."CLASS" ASC,
    ac."SUBCLASS" ASC;