SELECT
    o."object_id",
    o."title",
    TO_CHAR(TO_TIMESTAMP_NTZ(o."metadata_date" / 1000000), 'YYYY-MM-DD') AS "metadata_date"
FROM THE_MET.THE_MET.OBJECTS o
JOIN THE_MET.THE_MET.VISION_API_DATA t ON o."object_id" = t."object_id"
WHERE
    o."department" = 'The Libraries'
    AND o."title" LIKE '%book%'
    AND (t."cropHintsAnnotation":cropHints[0]:confidence)::FLOAT > 0.5;