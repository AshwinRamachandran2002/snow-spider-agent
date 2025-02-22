-- Task: What are the titles, artist names, mediums, and original image URLs of objects from the 'Photographs' department?

SELECT o."title", o."artist_display_name", o."medium", i."original_image_url"
FROM THE_MET.THE_MET.OBJECTS o
JOIN THE_MET.THE_MET.IMAGES i ON o."object_id" = i."object_id"
WHERE o."department" = 'Photographs';