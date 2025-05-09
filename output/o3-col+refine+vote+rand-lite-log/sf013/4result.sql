WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM("LENGTH_M"::DOUBLE) AS "AMSTERDAM_LENGTH_M"
    FROM
        NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
    WHERE
        "QUADKEY" LIKE '12020210%'     -- Amsterdam grid
        AND "LENGTH_M" IS NOT NULL
    GROUP BY
        "CLASS",
        "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM("LENGTH_M"::DOUBLE) AS "ROTTERDAM_LENGTH_M"
    FROM
        NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
    WHERE
        "QUADKEY" LIKE '12020211%'     -- Rotterdam grid
        AND "LENGTH_M" IS NOT NULL
    GROUP BY
        "CLASS",
        "SUBCLASS"
)
SELECT
    COALESCE(a."CLASS", r."CLASS")     AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",
    a."AMSTERDAM_LENGTH_M",
    r."ROTTERDAM_LENGTH_M"
FROM
    amsterdam a
FULL OUTER JOIN
    rotterdam r
ON  a."CLASS" = r."CLASS"
AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";