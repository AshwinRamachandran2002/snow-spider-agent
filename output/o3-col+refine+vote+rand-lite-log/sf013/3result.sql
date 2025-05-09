/*  Side-by-side comparison of total road length (in meters) 
    for Amsterdam (QUADKEY prefix '12020210') vs. Rotterdam ('12020211')  */

WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(CAST("LENGTH_M" AS DOUBLE)) AS "total_length_m_amsterdam"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" LIKE '12020210%'
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(CAST("LENGTH_M" AS DOUBLE)) AS "total_length_m_rotterdam"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" LIKE '12020211%'
    GROUP BY "CLASS", "SUBCLASS"
)

SELECT
    COALESCE(a."CLASS", r."CLASS")        AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS")  AS "SUBCLASS",
    a."total_length_m_amsterdam"          AS "amsterdam_length_m",
    r."total_length_m_rotterdam"          AS "rotterdam_length_m"
FROM amsterdam a
FULL OUTER JOIN rotterdam r
  ON a."CLASS" = r."CLASS"
 AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";