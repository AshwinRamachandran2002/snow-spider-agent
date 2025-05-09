SELECT DISTINCT
  o.title,
  o.artist_display_name AS artist_name,
  o.medium,
  i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images`  AS i
  ON o.object_id = i.object_id
WHERE
  o.department = 'Photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'        -- objects with “Photograph” in their names
  AND o.object_end_date <= 1839                       -- created in 1839 or earlier
  AND o.artist_display_name IS NOT NULL               -- artist is known
  AND LOWER(o.artist_display_name) NOT LIKE '%unknown%' ;