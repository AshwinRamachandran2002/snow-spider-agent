SELECT o.title, o.artist_display_name, o.medium, i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images` AS i ON o.object_id = i.object_id
WHERE o.department = 'Photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'
  AND o.object_end_date <= 1839
  AND LOWER(o.artist_display_name) NOT LIKE '%unknown%'