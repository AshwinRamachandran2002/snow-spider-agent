SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020210%' 
                THEN NVL(TRY_CAST("LENGTH_M" AS FLOAT),0)
                ELSE 0 
            END
        ),4
    ) AS "AMSTERDAM_LENGTH_M",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020211%' 
                THEN NVL(TRY_CAST("LENGTH_M" AS FLOAT),0)
                ELSE 0 
            END
        ),4
    ) AS "ROTTERDAM_LENGTH_M"
FROM
    "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
WHERE
    "QUADKEY" LIKE '12020210%' 
    OR "QUADKEY" LIKE '12020211%'
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS" ASC,
    "SUBCLASS" ASC;