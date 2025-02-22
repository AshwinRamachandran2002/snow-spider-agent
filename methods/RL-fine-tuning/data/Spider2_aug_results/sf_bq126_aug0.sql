-- Task: Retrieve the titles, artist display names, mediums, and original image URLs of objects from the 'Photographs' department where the object name contains 'Photograph' (case-insensitive), the artist is known (i.e., artist display name is neither null nor 'Unknown'), and the object end date is 1839 or earlier.
SELECT o."title", o."artist_display_name", o."medium", i."original_image_url"
FROM THE_MET.THE_MET.OBJECTS o
JOIN THE_MET.THE_MET.IMAGES i ON o."object_id" = i."object_id"
WHERE o."object_name" ILIKE '%Photograph%'
  AND o."department" = 'Photographs'
  AND o."artist_display_name" IS NOT NULL
  AND o."artist_display_name" != 'Unknown'
  AND o."object_end_date" <= 1839;