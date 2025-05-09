SELECT
  user AS user_id,
  COUNT(1) AS total_clicks
FROM (
  SELECT user FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_1`
  UNION ALL
  SELECT user FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_2`
  UNION ALL
  SELECT user FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_3`
)
WHERE user IS NOT NULL
GROUP BY user
ORDER BY total_clicks DESC, user_id
LIMIT 1;