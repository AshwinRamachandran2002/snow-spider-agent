WITH "FILTERED_ROADS" AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COALESCE(TRY_TO_DOUBLE("LENGTH_M"), 0) AS "LENGTH_M_NUM",
        "QUADKEY"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020210%'   -- Amsterdam quadkey segment
       OR "QUADKEY" LIKE '12020211%'   -- Rotterdam quadkey segment
)

SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020210%' 
                THEN "LENGTH_M_NUM" 
                ELSE 0 
            END
        ), 4
    ) AS "AMSTERDAM_TOTAL_LENGTH_M",
    ROUND(
        SUM(
            CASE 
                WHEN "QUADKEY" LIKE '12020211%' 
                THEN "LENGTH_M_NUM" 
                ELSE 0 
            END
        ), 4
    ) AS "ROTTERDAM_TOTAL_LENGTH_M"
FROM "FILTERED_ROADS"
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";