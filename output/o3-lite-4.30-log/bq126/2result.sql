SELECT DISTINCT
  obj.title               AS title,
  obj.artist_display_name AS artist,
  obj.medium              AS medium,
  img.original_image_url  AS original_image_url
FROM `bigquery-public-data.the_met.objects` AS obj
JOIN `bigquery-public-data.the_met.images`  AS img
  ON obj.object_id = img.object_id
WHERE obj.department = 'Photographs'
  AND LOWER(obj.object_name) LIKE '%photograph%'
  AND LOWER(obj.artist_display_name) NOT LIKE 'unknown%'
  AND obj.object_end_date <= 1839;