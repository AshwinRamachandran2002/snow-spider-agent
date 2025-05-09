-- Side-by-side comparison of total road lengths (in metres) for Amsterdam
-- (quadkey starts with ‘12020210’) versus Rotterdam (‘12020211’)  
WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_DOUBLE("LENGTH_M")) AS "AMSTERDAM_TOTAL_M"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" ILIKE '12020210%'      -- Amsterdam quadkey segment
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_DOUBLE("LENGTH_M")) AS "ROTTERDAM_TOTAL_M"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" ILIKE '12020211%'      -- Rotterdam quadkey segment
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(a."CLASS", r."CLASS")       AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",
    a."AMSTERDAM_TOTAL_M",
    r."ROTTERDAM_TOTAL_M"
FROM amsterdam a
FULL OUTER JOIN rotterdam r
  ON a."CLASS" = r."CLASS"
 AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY
    COALESCE(a."CLASS", r."CLASS"),
    COALESCE(a."SUBCLASS", r."SUBCLASS");