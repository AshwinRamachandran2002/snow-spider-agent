WITH url_flags AS (
  SELECT
    i.original_url,
    MAX(IF(l.label_name = '/m/01yrx' AND l.confidence = 1, 1, 0)) AS is_cat
  FROM `bigquery-public-data.open_images.images`   AS i
  LEFT JOIN `bigquery-public-data.open_images.labels` AS l
    ON i.image_id = l.image_id
  GROUP BY i.original_url               -- guarantees each URL appears once
)

SELECT
  CASE WHEN is_cat = 1 THEN 'cat' ELSE 'other' END AS category,
  COUNT(*) AS url_count
FROM url_flags
GROUP BY category;