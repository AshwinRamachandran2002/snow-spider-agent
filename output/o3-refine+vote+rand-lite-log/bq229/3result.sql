WITH cat_images AS (
  -- all images positively labeled as "cat"  (label_name = '/m/01yrx' and confidence = 1)
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1
),
categorized_urls AS (
  -- bring in the URLs and tag each one as 'cat' or 'other'
  SELECT
    CASE WHEN ci.image_id IS NOT NULL THEN 'cat' ELSE 'other' END AS category,
    i.original_url
  FROM `bigquery-public-data.open_images.images` AS i
  LEFT JOIN cat_images AS ci
  USING (image_id)
  WHERE i.original_url IS NOT NULL           -- keep only valid URLs
)
SELECT
  category,
  COUNT(DISTINCT original_url) AS distinct_url_count
FROM categorized_urls
GROUP BY category;