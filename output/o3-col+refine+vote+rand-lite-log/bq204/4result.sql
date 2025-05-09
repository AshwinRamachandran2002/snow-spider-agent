-- Find the user with the highest total number of photo records 
-- across all three photo collections
WITH all_clicks AS (
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_1`
  UNION ALL
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_2`
  UNION ALL
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_3`
)
SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM all_clicks
GROUP BY `user`
ORDER BY total_clicks DESC
LIMIT 1;