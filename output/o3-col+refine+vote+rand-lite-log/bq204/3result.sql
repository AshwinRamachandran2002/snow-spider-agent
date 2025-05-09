-- user with the most photos (clicks) across all three photo collections
WITH all_clicks AS (
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
  WHERE _TABLE_SUFFIX IN ('1','2','3')   -- v_0_1, v_0_2, v_0_3
)
SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM all_clicks
GROUP BY `user`
ORDER BY total_clicks DESC
LIMIT 1;