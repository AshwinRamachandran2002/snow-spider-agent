WITH all_photos AS (
  -- Combine the `user` column from every photo collection
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_1`
  UNION ALL
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_2`
  UNION ALL
  SELECT `user`
  FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_3`
)

-- Count total photos (“clicks”) per user and return the top one
SELECT
  `user`,
  COUNT(*) AS total_clicks
FROM all_photos
GROUP BY `user`
ORDER BY total_clicks DESC
LIMIT 1;