-- Task: Find the user with the highest number of photo submissions across the photos_v_0_1, photos_v_0_2, and photos_v_0_3 tables, excluding null and empty usernames.
SELECT `user`, COUNT(*) AS total_clicks
FROM (
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_1`
  UNION ALL
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_2`
  UNION ALL
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_3`
)
WHERE `user` IS NOT NULL AND `user` != ''
GROUP BY `user`
ORDER BY total_clicks DESC
LIMIT 1;