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