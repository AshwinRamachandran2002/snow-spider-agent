-- Task: List the top 100 female baby names in Wyoming in 2021 along with the number of babies with that name in Wyoming and the total number of babies with that name across all states in 2021.

SELECT wy_names."name", wy_names."number" AS "WY_number", total_names.total_number
FROM
    (SELECT "name", SUM("number") AS "number"
     FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
     WHERE "state" = 'WY' AND "gender" = 'F' AND "year" = 2021
     GROUP BY "name") wy_names
JOIN
    (SELECT "name", SUM("number") AS total_number
     FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
     WHERE "gender" = 'F' AND "year" = 2021
     GROUP BY "name") total_names
ON wy_names."name" = total_names."name"
ORDER BY wy_names."number" DESC
LIMIT 100;