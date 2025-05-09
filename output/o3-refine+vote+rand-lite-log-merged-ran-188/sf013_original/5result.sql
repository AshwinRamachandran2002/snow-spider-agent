WITH road_city AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COALESCE(TRY_TO_DOUBLE("LENGTH_M"), 0)                         AS "LENGTH_M_NUM",
        CASE
            WHEN "QUADKEY" LIKE '12020210%' THEN 'Amsterdam'
            WHEN "QUADKEY" LIKE '12020211%' THEN 'Rotterdam'
        END                                                         AS "CITY"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020210%' 
       OR "QUADKEY" LIKE '12020211%'
)
SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(SUM(CASE WHEN "CITY" = 'Amsterdam'  THEN "LENGTH_M_NUM" END), 4) AS "AMSTERDAM_LENGTH_M",
    ROUND(SUM(CASE WHEN "CITY" = 'Rotterdam' THEN "LENGTH_M_NUM" END), 4) AS "ROTTERDAM_LENGTH_M"
FROM road_city
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";