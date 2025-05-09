WITH
-- 1.  Administrative geometries for the two cities
AMSTERDAM AS (
    SELECT ST_UNION_AGG("GEO_CORDINATES") AS GEOM
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'          -- municipality level
      AND  LOWER("NAMES"::string) LIKE '%amsterdam%'
),
ROTTERDAM AS (
    SELECT ST_UNION_AGG("GEO_CORDINATES") AS GEOM
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'
      AND  LOWER("NAMES"::string) LIKE '%rotterdam%'
),

-- 2.  Roads only in the two requested QUADKEY‑prefix tiles
ROADS AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        "LENGTH_M"::DOUBLE      AS LENGTH_M,
        "GEO_CORDINATES"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE  SUBSTR("QUADKEY", 1, 8) IN ('12020210', '12020211')
      AND  "LENGTH_M" IS NOT NULL
),

-- 3.  Lengths per class / subclass inside Amsterdam
AMSTERDAM_LENGTHS AS (
    SELECT
        r."CLASS"   AS CLASS,
        r."SUBCLASS" AS SUBCLASS,
        SUM(r.LENGTH_M) AS AMSTERDAM_LENGTH_M
    FROM   ROADS r,
           AMSTERDAM a
    WHERE  ST_INTERSECTS(r."GEO_CORDINATES", a.GEOM)
    GROUP BY r."CLASS", r."SUBCLASS"
),

-- 4.  Lengths per class / subclass inside Rotterdam
ROTTERDAM_LENGTHS AS (
    SELECT
        r."CLASS"   AS CLASS,
        r."SUBCLASS" AS SUBCLASS,
        SUM(r.LENGTH_M) AS ROTTERDAM_LENGTH_M
    FROM   ROADS r,
           ROTTERDAM rt
    WHERE  ST_INTERSECTS(r."GEO_CORDINATES", rt.GEOM)
    GROUP BY r."CLASS", r."SUBCLASS"
)

-- 5.  Side‑by‑side comparison
SELECT
    COALESCE(a.CLASS, r.CLASS)      AS "CLASS",
    COALESCE(a.SUBCLASS, r.SUBCLASS) AS "SUBCLASS",
    a.AMSTERDAM_LENGTH_M,
    r.ROTTERDAM_LENGTH_M
FROM        AMSTERDAM_LENGTHS a
FULL  JOIN  ROTTERDAM_LENGTHS r
       ON   a.CLASS    = r.CLASS
      AND   a.SUBCLASS = r.SUBCLASS
ORDER BY "CLASS", "SUBCLASS";