-- Task: Find the total number of unique users across all records from all available photo collections.
SELECT COUNT(DISTINCT `user`) AS total_users
FROM (
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_1`
  UNION ALL
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_2`
  UNION ALL
  SELECT `user` FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_3`
)
WHERE `user` IS NOT NULL AND `user` != '';