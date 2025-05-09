/*-----------------------------------------------------------
  Compare total road length (m) for each (class, subclass)
  between Amsterdam and Rotterdam within quadkeys 12020210*
  and 12020211*
-----------------------------------------------------------*/
WITH
/* --- 1.  Single boundary polygon for Amsterdam ------------*/
amsterdam AS (
    SELECT
        'Amsterdam'                       AS CITY,
        "GEO_CORDINATES"                  AS GEOM
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"
    WHERE "ADMIN_LEVEL" = '8'
      AND LOWER(TO_VARCHAR("NAMES")) LIKE '%amsterdam%'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "ID") = 1
),
/* --- 2.  Single boundary polygon for Rotterdam ------------*/
rotterdam AS (
    SELECT
        'Rotterdam'                       AS CITY,
        "GEO_CORDINATES"                  AS GEOM
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"
    WHERE "ADMIN_LEVEL" = '8'
      AND LOWER(TO_VARCHAR("NAMES")) LIKE '%rotterdam%'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "ID") = 1
),
/* --- 3.  Union both cities into one CTE -------------------*/
city_boundaries AS (
    SELECT * FROM amsterdam
    UNION ALL
    SELECT * FROM rotterdam
),
/* --- 4.  Road segments in requested quadkey prefixes ------*/
road_segments AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        "GEO_CORDINATES",
        COALESCE(TRY_TO_DOUBLE("LENGTH_M"), 0) AS LENGTH_M
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
    WHERE "QUADKEY" LIKE '12020210%' OR "QUADKEY" LIKE '12020211%'
),
/* --- 5.  Assign each segment to the city it falls within --*/
city_roads AS (
    SELECT
        r."CLASS",
        r."SUBCLASS",
        c.CITY,
        r.LENGTH_M
    FROM road_segments r
    JOIN city_boundaries c
      ON ST_WITHIN(r."GEO_CORDINATES", c.GEOM)
)
/* --- 6.  Aggregate total length per (class, subclass) -----*/
SELECT
    "CLASS",
    "SUBCLASS",
    SUM(CASE WHEN CITY = 'Amsterdam' THEN LENGTH_M ELSE 0 END) AS "AMSTERDAM_LENGTH_M",
    SUM(CASE WHEN CITY = 'Rotterdam' THEN LENGTH_M ELSE 0 END) AS "ROTTERDAM_LENGTH_M"
FROM city_roads
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";