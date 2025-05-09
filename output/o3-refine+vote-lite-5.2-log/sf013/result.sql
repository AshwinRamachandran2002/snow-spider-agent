SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020210%' 
                THEN COALESCE(TRY_TO_DOUBLE("LENGTH_M"),0) 
                ELSE 0 
            END
        ), 4
    ) AS "AMSTERDAM_LENGTH_M",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020211%' 
                THEN COALESCE(TRY_TO_DOUBLE("LENGTH_M"),0) 
                ELSE 0 
            END
        ), 4
    ) AS "ROTTERDAM_LENGTH_M"
FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
WHERE "QUADKEY" LIKE '12020210%' 
   OR "QUADKEY" LIKE '12020211%'
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";