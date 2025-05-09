SELECT wy_names."name"
FROM (
    SELECT "name", "number"
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "state" = 'WY' AND "gender" = 'F' AND "year" = 2021
) AS wy_names
JOIN (
    SELECT "name", SUM("number") AS total_number
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F' AND "year" = 2021
    GROUP BY "name"
) AS total_names
ON wy_names."name" = total_names."name"
ORDER BY (wy_names."number" / total_names.total_number) DESC NULLS LAST
LIMIT 1;