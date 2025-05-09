WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "AMS_LEN_M"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" ILIKE '12020210%'               -- Amsterdam segment
      AND TRY_TO_NUMBER("LENGTH_M") IS NOT NULL     -- keep numeric values only
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM(TRY_TO_NUMBER("LENGTH_M")) AS "RTM_LEN_M"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
    WHERE "QUADKEY" ILIKE '12020211%'               -- Rotterdam segment
      AND TRY_TO_NUMBER("LENGTH_M") IS NOT NULL
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(amsterdam."CLASS",     rotterdam."CLASS")     AS "CLASS",
    COALESCE(amsterdam."SUBCLASS",  rotterdam."SUBCLASS")  AS "SUBCLASS",
    amsterdam."AMS_LEN_M",
    rotterdam."RTM_LEN_M"
FROM amsterdam
FULL OUTER JOIN rotterdam
       ON  amsterdam."CLASS"    = rotterdam."CLASS"
       AND amsterdam."SUBCLASS" = rotterdam."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";