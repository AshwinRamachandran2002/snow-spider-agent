SELECT
  o.title,
  o.artist_display_name AS artist,
  o.medium,
  i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images`  AS i
  ON o.object_id = i.object_id
WHERE o.department = 'Photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'
  AND LOWER(o.artist_display_name) NOT LIKE 'unknown%'
  AND o.object_end_date <= 1839
QUALIFY ROW_NUMBER() OVER (PARTITION BY o.object_id ORDER BY i.original_image_url) = 1;