SELECT
  obj.title,
  obj.artist_display_name AS artist_name,
  obj.medium,
  ANY_VALUE(img.original_image_url) AS original_image_url
FROM
  `bigquery-public-data.the_met.objects` AS obj
JOIN
  `bigquery-public-data.the_met.images` AS img
ON
  obj.object_id = img.object_id
WHERE
  LOWER(obj.object_name) LIKE '%photograph%'      -- object name contains 'Photograph'
  AND obj.department = 'Photographs'              -- in the Photographs department
  AND obj.artist_display_name IS NOT NULL         -- artist is known
  AND LOWER(obj.artist_display_name) NOT LIKE '%unknown%'
  AND obj.object_end_date <= 1839                 -- created in 1839 or earlier
GROUP BY
  obj.object_id, obj.title, artist_name, obj.medium;