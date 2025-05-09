SELECT DISTINCT
  o.object_id,
  o.title,
  FORMAT_DATE('%F', DATE(o.metadata_date)) AS metadata_date
FROM `bigquery-public-data.the_met.objects`        AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.object_id = v.object_id
WHERE o.department = 'The Libraries'
  AND o.title IS NOT NULL
  AND REGEXP_CONTAINS(LOWER(o.title), r'\bbook\b')       -- title contains the word "book"
  AND EXISTS (                                           -- at least one crop hint with confidence > 0.5
        SELECT 1
        FROM UNNEST(v.cropHintsAnnotation.cropHints) AS ch
        WHERE ch.confidence > 0.5
      );