SELECT
  o.title,
  o.artist_display_name AS artist_name,
  o.medium,
  ARRAY_AGG(i.original_image_url ORDER BY i.original_image_url LIMIT 1)[OFFSET(0)] AS original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images`  AS i
  ON o.object_id = i.object_id
WHERE LOWER(o.object_name)     LIKE '%photograph%'   -- object name contains 'Photograph'
  AND o.department             = 'Photographs'       -- belongs to Photographs department
  AND o.object_end_date        <= 1839               -- dated 1839 or earlier
  AND LOWER(IFNULL(o.artist_display_name,'')) NOT LIKE '%unknown%'  -- artist is not “unknown”
GROUP BY
  o.object_id,               -- ensures one row per object
  o.title,
  o.artist_display_name,
  o.medium;