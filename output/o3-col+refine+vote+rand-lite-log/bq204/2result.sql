-- user with the greatest number of photos across every available v0_* photo table
SELECT `user`
FROM (
  SELECT `user`, COUNT(*) AS total_clicks
  FROM   `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
  GROUP  BY `user`
  ORDER  BY total_clicks DESC
  LIMIT  1
);