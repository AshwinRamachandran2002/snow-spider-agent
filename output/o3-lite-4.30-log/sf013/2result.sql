WITH city_polygons AS (  -- Amsterdam & Rotterdam municipality polygons
    SELECT
        CASE
            WHEN "NAMES"::STRING ILIKE '%Amsterdam%' THEN 'Amsterdam'
            WHEN "NAMES"::STRING ILIKE '%Rotterdam%' THEN 'Rotterdam'
        END                       AS "CITY",
        "GEO_CORDINATES"          AS "GEOM"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE "ADMIN_LEVEL" = '8'
      AND (
            "NAMES"::STRING ILIKE '%Amsterdam%' 
         OR "NAMES"::STRING ILIKE '%Rotterdam%'
      )
), candidate_roads AS (        -- roads in the two required quadkey families
    SELECT
        "ID",
        "CLASS",
        "SUBCLASS",
        TRY_TO_NUMBER("LENGTH_M")  AS "LENGTH_M",
        "GEO_CORDINATES"           AS "GEOM"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020210%' 
       OR "QUADKEY" LIKE '12020211%'
), city_roads AS (             -- keep each road once per city
    SELECT
        r."CLASS",
        r."SUBCLASS",
        r."LENGTH_M",
        c."CITY"
    FROM candidate_roads r
    JOIN city_polygons c
      ON ST_INTERSECTS(c."GEOM", r."GEOM")
    QUALIFY ROW_NUMBER() OVER (PARTITION BY r."ID", c."CITY" ORDER BY r."ID") = 1
)
SELECT
    "CLASS"                                        AS class,
    "SUBCLASS"                                     AS subclass,
    ROUND(SUM(CASE WHEN "CITY" = 'Amsterdam' THEN "LENGTH_M" END), 4)  AS amsterdam_road_length_m,
    ROUND(SUM(CASE WHEN "CITY" = 'Rotterdam' THEN "LENGTH_M" END), 4)  AS rotterdam_road_length_m
FROM city_roads
GROUP BY "CLASS", "SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";