WITH url_flags AS (
  SELECT
    i.original_url,
    COUNTIF(b.label_name = '/m/01yrx' AND b.confidence = 1) > 0 AS is_cat
  FROM `bigquery-public-data.open_images.images` AS i
  LEFT JOIN `bigquery-public-data.open_images.annotations_bbox` AS b
    ON i.image_id = b.image_id
  GROUP BY i.original_url
)
SELECT
  CASE WHEN is_cat THEN 'cat' ELSE 'other' END AS category,
  COUNT(*) AS distinct_url_count
FROM url_flags
GROUP BY category;