SELECT
  CASE WHEN l.image_id IS NOT NULL THEN 'Cat' ELSE 'Other' END AS Category,
  COUNT(DISTINCT i.image_id) AS Count
FROM `bigquery-public-data.open_images.images` AS i
LEFT JOIN (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx' AND confidence = 1.0
) AS l
ON i.image_id = l.image_id
GROUP BY Category
ORDER BY Category;