-- Task: Retrieve the titles, artist names, mediums, and original image URLs of objects from the 'Photographs' department where the object name includes 'photograph' (case-insensitive), created by a known artist (i.e., artist display name is not 'Unknown' or empty), with an object end date of 1839 or earlier, and where the title, medium, and original image URL are not null.

SELECT o.title, o.artist_display_name, o.medium, i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images` AS i
ON o.object_id = i.object_id
WHERE LOWER(o.object_name) LIKE '%photograph%'
  AND o.department = 'Photographs'
  AND o.artist_display_name IS NOT NULL
  AND o.artist_display_name NOT IN ('Unknown', '')
  AND o.object_end_date <= 1839
  AND o.title IS NOT NULL
  AND o.medium IS NOT NULL
  AND i.original_image_url IS NOT NULL;