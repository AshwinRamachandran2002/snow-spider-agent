-- Titles, artists, mediums, and image URLs for early (≤ 1839) “Photograph” objects
SELECT
  o.title                                AS title,
  o.artist_display_name                  AS artist_name,
  o.medium                               AS medium,
  ARRAY_AGG(i.original_image_url ORDER BY i.original_image_url LIMIT 1)[OFFSET(0)]
                                         AS original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images`  AS i
  ON o.object_id = i.object_id
WHERE o.department = 'Photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'     -- object name contains “photograph”
  AND o.object_end_date <= 1839                    -- created in 1839 or earlier
  AND o.artist_display_name IS NOT NULL            -- ensure artist listed
  AND LOWER(o.artist_display_name) NOT LIKE '%unknown%'  -- exclude unknown artists
GROUP BY
  o.object_id,
  o.title,
  o.artist_display_name,
  o.medium,
  o.object_end_date
ORDER BY o.object_end_date;