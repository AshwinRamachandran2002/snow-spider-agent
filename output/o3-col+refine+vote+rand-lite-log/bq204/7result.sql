-- Find the account with the greatest number of photo “clicks”
-- across every versioned photo table in the dataset.
SELECT
  user,
  COUNT(*) AS total_clicks
FROM `bigquery-public-data.eclipse_megamovie.photos_v_0_*`
WHERE user IS NOT NULL                -- safety: ignore rows without a user id
GROUP BY user
ORDER BY total_clicks DESC
LIMIT 1;