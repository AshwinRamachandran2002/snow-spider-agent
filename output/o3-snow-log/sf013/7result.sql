WITH roads AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        /* length (TEXT) → numeric, filtered to the two quadkey prefixes               */
        CASE 
            WHEN "QUADKEY" LIKE '12020210%' 
                 THEN COALESCE(TRY_TO_DOUBLE("LENGTH_M"),0) 
            ELSE 0 
        END AS length_amsterdam,
        CASE 
            WHEN "QUADKEY" LIKE '12020211%' 
                 THEN COALESCE(TRY_TO_DOUBLE("LENGTH_M"),0) 
            ELSE 0 
        END AS length_rotterdam
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ROAD
    WHERE "QUADKEY" LIKE '12020210%'   -- Amsterdam quadkey segment
       OR "QUADKEY" LIKE '12020211%'   -- Rotterdam quadkey segment
)
SELECT
    "CLASS",
    "SUBCLASS",
    ROUND(SUM(length_amsterdam), 4)  AS "AMSTERDAM_LENGTH_M",
    ROUND(SUM(length_rotterdam), 4)  AS "ROTTERDAM_LENGTH_M"
FROM roads
GROUP BY
    "CLASS",
    "SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";