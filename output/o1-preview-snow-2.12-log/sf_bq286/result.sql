SELECT "name"
FROM (
    SELECT wy_names."name",
           ROUND(wy_names."number"::FLOAT / total_names.total_number, 4) AS proportion
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
)
ORDER BY proportion DESC NULLS LAST, "name" ASC
LIMIT 1;