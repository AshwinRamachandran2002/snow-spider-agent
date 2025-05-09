WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        ROUND(SUM(TRY_TO_NUMBER("LENGTH_M")), 4) AS amsterdam_road_length_m
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" LIKE '12020210%'
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        ROUND(SUM(TRY_TO_NUMBER("LENGTH_M")), 4) AS rotterdam_road_length_m
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" LIKE '12020211%'
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(a."CLASS", r."CLASS")     AS class,
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS subclass,
    a.amsterdam_road_length_m,
    r.rotterdam_road_length_m
FROM amsterdam a
FULL OUTER JOIN rotterdam r
  ON a."CLASS" = r."CLASS"
 AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY class, subclass;