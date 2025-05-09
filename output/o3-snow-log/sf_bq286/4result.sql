WITH total AS (
    SELECT 
        "name", 
        SUM("number") AS "total_num"
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year" = 2021
    GROUP BY "name"
), wy AS (
    SELECT 
        "name", 
        SUM("number") AS "wy_num"
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year" = 2021
      AND "state" = 'WY'
    GROUP BY "name"
)
SELECT 
    wy."name"
FROM wy
JOIN total USING ("name")
ORDER BY (wy."wy_num" / total."total_num") DESC NULLS LAST
LIMIT 1;