-- User with the greatest number of photo “clicks” (i.e., total uploaded photos)
SELECT
  `user`,
  COUNT(1) AS total_clicks
FROM
  `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
GROUP BY
  `user`
ORDER BY
  total_clicks DESC
LIMIT 1;