SELECT 
  'Good' AS health_status,
  ROUND(AVG(CASE WHEN "health" = 'Good' THEN 1.0 ELSE 0 END) * 100, 4) AS percentage
FROM "trees"
WHERE "boroname" = 'Bronx';