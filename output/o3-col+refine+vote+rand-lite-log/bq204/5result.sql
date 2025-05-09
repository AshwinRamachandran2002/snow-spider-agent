-- Find the user with the most total photo “clicks” across every photos_v_* table
SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM
  `bigquery-public-data.eclipse_megamovie.photos_v_0_*`   -- wildcard covers v_0_1, v_0_2, v_0_3, etc.
GROUP BY
  `user`
ORDER BY
  total_clicks DESC
LIMIT
  1;