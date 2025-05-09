SELECT
    CASE
        WHEN "QUADKEY" LIKE '12020210%' THEN 'Amsterdam'
        WHEN "QUADKEY" LIKE '12020211%' THEN 'Rotterdam'
    END AS "City",
    "CLASS" AS "Class",
    "SUBCLASS" AS "Subclass",
    ROUND(SUM(CAST(NULLIF("LENGTH_M", '') AS FLOAT)), 4) AS "Total_Road_Length_meters"
FROM
    "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ROAD"
WHERE
    ("QUADKEY" LIKE '12020210%' OR "QUADKEY" LIKE '12020211%')
    AND "LENGTH_M" <> ''
GROUP BY
    "City",
    "Class",
    "Subclass"
ORDER BY
    "City",
    "Total_Road_Length_meters" DESC NULLS LAST;