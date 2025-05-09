SELECT DISTINCT
       o."object_id"                                                   AS OBJECT_ID,
       o."title"                                                       AS TITLE,
       TO_CHAR(TO_TIMESTAMP(o."metadata_date" / 1000), 'YYYY-MM-DD')   AS METADATA_DATE
FROM THE_MET.THE_MET.OBJECTS         AS o
JOIN THE_MET.THE_MET.VISION_API_DATA AS v
      ON o."object_id" = v."object_id"
JOIN LATERAL FLATTEN(
         INPUT => TRY_PARSE_JSON(v."cropHintsAnnotation"):cropHints
     ) AS f
WHERE o."department" = 'The Libraries'
  AND LOWER(o."title") LIKE '%book%'
  AND f.value:"confidence"::FLOAT > 0.5;