-- User with the highest total number of photo “clicks” (rows) 
-- aggregated across every available photos collection.
SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM
  `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
GROUP BY
  `user`
ORDER BY
  total_clicks DESC
LIMIT 1;