SELECT
  ROUND(
    AVG(CASE WHEN "health" = 'Good' THEN 1.0 ELSE 0 END) * 100,
    4
  ) AS "percentage_good_in_bronx"
FROM "trees"
WHERE "boroname" = 'Bronx';