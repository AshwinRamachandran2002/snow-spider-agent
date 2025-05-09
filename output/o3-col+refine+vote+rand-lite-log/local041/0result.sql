SELECT
  ROUND(
    SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) * 100.0
    / COUNT(*),
    4
  ) AS percentage_good_bronx
FROM "trees"
WHERE "boroname" = 'Bronx';