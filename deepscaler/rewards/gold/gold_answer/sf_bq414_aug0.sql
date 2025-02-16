-- Task: From the OBJECTS table, retrieve the object id, title, and the metadata date (formatted as 'YYYY-MM-DD') for objects in the 'The Libraries' department whose titles contain the word 'book'. Join these objects with the VISION_API_DATA table on 'object_id', extracting the 'confidence' values from the 'cropHints' within the 'cropHintsAnnotation' field. Include only objects where at least one 'confidence' value is greater than 0.5.
SELECT o."object_id", o."title", TO_VARCHAR(TO_TIMESTAMP(o."metadata_date" / 1e6), 'YYYY-MM-DD') AS "metadata_date"
FROM THE_MET.THE_MET.OBJECTS o
JOIN (
  SELECT t."object_id", f.value:"confidence"::FLOAT AS "confidence"
  FROM THE_MET.THE_MET.VISION_API_DATA t,
  LATERAL FLATTEN(input => t."cropHintsAnnotation":cropHints) f
) v ON o."object_id" = v."object_id"
WHERE o."department" = 'The Libraries'
  AND o."title" LIKE '%book%'
  AND v."confidence" > 0.5;