SELECT
  ROUND((COUNT(CASE WHEN "health" = 'Good' THEN 1 END)::FLOAT / COUNT(*) * 100), 4) AS "Percentage_of_trees_with_good_health_in_Bronx"
FROM MODERN_DATA.MODERN_DATA.TREES
WHERE "boroname" = 'Bronx';