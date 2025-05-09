SELECT DISTINCT
  o.object_id,
  o.title,
  FORMAT_DATE('%Y-%m-%d', DATE(o.metadata_date)) AS formatted_metadata_date
FROM `bigquery-public-data.the_met.objects`        AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.object_id = v.object_id
WHERE o.department = 'The Libraries'
  AND LOWER(IFNULL(o.title, '')) LIKE '%book%'
  AND v.cropHintsAnnotation IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM UNNEST(v.cropHintsAnnotation.cropHints) AS ch
        WHERE ch.confidence > 0.5
      );