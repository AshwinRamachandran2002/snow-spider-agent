WITH
/* ----------------------  Amsterdam : QUADKEY starts with 12020210  ---------------------- */
AMSTERDAM AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "AMSTERDAM_LENGTH_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
    WHERE "QUADKEY" LIKE '12020210%'
    GROUP BY "CLASS", "SUBCLASS"
),

/* ----------------------  Rotterdam : QUADKEY starts with 12020211  ---------------------- */
ROTTERDAM AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "ROTTERDAM_LENGTH_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
    WHERE "QUADKEY" LIKE '12020211%'
    GROUP BY "CLASS", "SUBCLASS"
)

/* ----------------------  Combine the two city summaries side‑by‑side  ------------------- */
SELECT
    COALESCE(a."CLASS", r."CLASS")       AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",
    ROUND(COALESCE(a."AMSTERDAM_LENGTH_M", 0), 4)  AS "AMSTERDAM_LENGTH_M",
    ROUND(COALESCE(r."ROTTERDAM_LENGTH_M", 0), 4)  AS "ROTTERDAM_LENGTH_M"
FROM AMSTERDAM a
FULL OUTER JOIN ROTTERDAM r
       ON a."CLASS"    = r."CLASS"
      AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";