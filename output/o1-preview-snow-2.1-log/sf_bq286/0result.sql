SELECT wy."name"
FROM
  (SELECT "name", "number"
   FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
   WHERE "state" = 'WY' AND "gender" = 'F' AND "year" = 2021) wy
JOIN
  (SELECT "name", SUM("number") AS total_number
   FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
   WHERE "gender" = 'F' AND "year" = 2021
   GROUP BY "name") us
ON wy."name" = us."name"
ORDER BY ROUND(wy."number" / us.total_number, 4) DESC NULLS LAST
LIMIT 1;