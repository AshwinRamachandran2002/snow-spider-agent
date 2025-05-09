SELECT DISTINCT
  o.object_id,
  o.title,
  FORMAT_TIMESTAMP('%F', o.metadata_date) AS metadata_date
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.object_id = v.object_id
CROSS JOIN UNNEST(v.cropHintsAnnotation.cropHints) AS h
WHERE o.department = 'The Libraries'
  AND LOWER(o.title) LIKE '%book%'
  AND h.confidence > 0.5;