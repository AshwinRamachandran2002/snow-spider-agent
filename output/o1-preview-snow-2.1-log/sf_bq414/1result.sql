SELECT DISTINCT o."object_id",
       o."title",
       TO_VARCHAR(TO_TIMESTAMP_NTZ(o."metadata_date" / 1e6), 'YYYY-MM-DD') AS "metadata_date"
FROM THE_MET.THE_MET."OBJECTS" o
JOIN THE_MET.THE_MET."VISION_API_DATA" v ON o."object_id" = v."object_id",
     LATERAL FLATTEN(input => v."cropHintsAnnotation":"cropHints") f
WHERE o."department" = 'The Libraries'
  AND o."title" LIKE '%book%'
  AND o."title" NOT LIKE '%Book Edges%'
  AND f.value:"confidence"::FLOAT > 0.5;