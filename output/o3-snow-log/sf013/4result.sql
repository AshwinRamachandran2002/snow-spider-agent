WITH roads_filtered AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        CASE 
            WHEN LEFT("QUADKEY", 8) = '12020210' THEN 'Amsterdam'
            WHEN LEFT("QUADKEY", 8) = '12020211' THEN 'Rotterdam'
        END                                               AS "CITY",
        TRY_TO_DOUBLE("LENGTH_M")                         AS "LENGTH_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE LEFT("QUADKEY", 8) IN ('12020210', '12020211')
)

SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(COALESCE(SUM(CASE WHEN "CITY" = 'Amsterdam'  THEN "LENGTH_M" END),0), 4) AS "AMSTERDAM_LENGTH_M",
    ROUND(COALESCE(SUM(CASE WHEN "CITY" = 'Rotterdam'  THEN "LENGTH_M" END),0), 4) AS "ROTTERDAM_LENGTH_M"
FROM roads_filtered
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";