/*  Side-by-side comparison of total road lengths (meters)
    for Amsterdam (quadkey prefix '12020210') and Rotterdam
    (quadkey prefix '12020211') by CLASS + SUBCLASS           */

WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "TOTAL_LENGTH_M_AMS"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" ILIKE '12020210%'
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "TOTAL_LENGTH_M_ROT"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" ILIKE '12020211%'
    GROUP BY "CLASS", "SUBCLASS"
)

SELECT
    COALESCE(a."CLASS",  r."CLASS")      AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",
    a."TOTAL_LENGTH_M_AMS",
    r."TOTAL_LENGTH_M_ROT"
FROM amsterdam a
FULL OUTER JOIN rotterdam r
  ON a."CLASS"    = r."CLASS"
 AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";