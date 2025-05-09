SELECT
  user,
  COUNT(*) AS total_clicks
FROM
  `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
WHERE
  user IS NOT NULL
GROUP BY
  user
ORDER BY
  total_clicks DESC,
  user
LIMIT 1;