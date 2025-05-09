/*  Calculate the summed road lengths (in metres) for Amsterdam-area
    quadkeys (starting with '12020210') and Rotterdam-area quadkeys
    (starting with '12020211'), broken down by every (class, subclass)
    combination.                                                   */

WITH AMSTERDAM AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_DOUBLE("LENGTH_M")) AS AMSTERDAM_LENGTH_M
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020210%'          -- Amsterdam tiles
    GROUP BY "CLASS", "SUBCLASS"
),
ROTTERDAM AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_DOUBLE("LENGTH_M")) AS ROTTERDAM_LENGTH_M
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020211%'          -- Rotterdam tiles
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(A."CLASS",  R."CLASS")      AS "CLASS",
    COALESCE(A."SUBCLASS", R."SUBCLASS") AS "SUBCLASS",
    A.AMSTERDAM_LENGTH_M,
    R.ROTTERDAM_LENGTH_M
FROM AMSTERDAM A
FULL OUTER JOIN ROTTERDAM R
      ON  A."CLASS"    = R."CLASS"
      AND A."SUBCLASS" = R."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";