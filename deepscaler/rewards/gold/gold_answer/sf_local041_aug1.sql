-- Task: Find the total number of trees in the Bronx that have a health status of Good
SELECT
  COUNT(*) AS "Number_of_trees_with_good_health_in_Bronx"
FROM
  MODERN_DATA.MODERN_DATA.TREES
WHERE
  "boroname" = 'Bronx' AND "health" = 'Good';