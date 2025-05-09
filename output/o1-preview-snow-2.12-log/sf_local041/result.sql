SELECT
  ROUND(
    100.0 * SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) / COUNT(*)
    , 4) AS "Percentage_of_trees_with_good_health_in_Bronx"
FROM
  MODERN_DATA.MODERN_DATA.TREES
WHERE
  "boroname" = 'Bronx';