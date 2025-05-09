WITH feature_toggle_keywords AS (
  SELECT 'unleash' AS keyword UNION ALL
  SELECT 'launchdarkly' UNION ALL
  SELECT 'flipper' UNION ALL
  SELECT 'ff4j' UNION ALL
  SELECT 'togglz' UNION ALL
  SELECT 'waffle' UNION ALL
  SELECT 'toggle'
)
SELECT DISTINCT
  p.repository_name_with_owner AS repository_full_name,
  p.repository_host_type AS hosting_platform_type,
  p.repository_size * 1024 AS size_bytes,
  p.repository_language AS primary_language,
  p.repository_fork_source_name_with_owner AS fork_source_name,
  p.repository_updated_timestamp AS last_update_timestamp,
  p.name AS artifact_name,
  p.name AS library_name,
  p.language AS library_programming_languages
FROM `bigquery-public-data.libraries_io.projects_with_repository_fields` AS p
JOIN feature_toggle_keywords AS ftk
  ON LOWER(p.name) LIKE CONCAT('%', ftk.keyword, '%')
     OR LOWER(p.keywords) LIKE CONCAT('%', ftk.keyword, '%')
WHERE p.repository_name_with_owner IS NOT NULL
LIMIT 100