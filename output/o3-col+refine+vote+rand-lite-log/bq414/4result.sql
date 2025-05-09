SELECT DISTINCT
  o.object_id,
  o.title,
  FORMAT_DATE('%F', DATE(o.metadata_date)) AS metadata_date_yyyy_mm_dd
FROM `bigquery-public-data.the_met.objects`        AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.object_id = v.object_id
CROSS JOIN UNNEST(IFNULL(v.cropHintsAnnotation.cropHints, [])) AS hint
WHERE hint.confidence > 0.5
  AND o.department = 'The Libraries'
  AND LOWER(o.title) LIKE '%book%';