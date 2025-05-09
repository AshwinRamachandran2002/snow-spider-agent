SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM
  `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
WHERE
  _TABLE_SUFFIX IN ('1', '2', '3')      -- include every known photo collection
  AND `user` IS NOT NULL                -- disregard records without a user ID
GROUP BY
  `user`
ORDER BY
  total_clicks DESC
LIMIT 1;