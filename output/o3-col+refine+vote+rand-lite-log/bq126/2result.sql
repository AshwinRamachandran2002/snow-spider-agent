SELECT
  o.title                         AS title,
  o.artist_display_name           AS artist_name,
  o.medium                        AS medium,
  ANY_VALUE(i.original_image_url) AS original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
LEFT JOIN `bigquery-public-data.the_met.images`  AS i
       ON o.object_id = i.object_id
WHERE o.department = 'Photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'
  AND o.object_end_date <= 1839
  AND o.artist_display_name IS NOT NULL
  AND LOWER(o.artist_display_name) NOT LIKE '%unknown%'
  AND LOWER(o.artist_display_name) NOT LIKE '%anonymous%'
GROUP BY o.object_id, o.title, o.artist_display_name, o.medium;