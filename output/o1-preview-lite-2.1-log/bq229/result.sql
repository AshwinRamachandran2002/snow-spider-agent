SELECT
  CASE WHEN cat.image_id IS NOT NULL THEN 'Cat' ELSE 'Other' END AS Category,
  COUNT(DISTINCT i.image_id) AS Count
FROM
  `bigquery-public-data.open_images.images` AS i
LEFT JOIN (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx' AND confidence = 1.0
) AS cat ON i.image_id = cat.image_id
WHERE i.original_url IS NOT NULL AND i.original_url != ''
GROUP BY Category;