/*  Repositories that use popular feature-toggle libraries
    (Unleash, LaunchDarkly, Togglz, FF4J, Flip, Bandiera).

    Returned per repo:
      – full name (owner/repo) and hosting platform
      – repo size in bytes, primary language, fork source, last-update time
      – exact artefact referenced in the manifest (artifact_name_used)
      – normalised library family name, its package-manager platform and language
*/
WITH feature_libs AS (
  SELECT 'unleash'       AS keyword, 'Unleash'       AS library_name UNION ALL
  SELECT 'launchdarkly'  , 'LaunchDarkly'                         UNION ALL
  SELECT 'togglz'        , 'Togglz'                               UNION ALL
  SELECT 'ff4j'          , 'FF4J'                                 UNION ALL
  SELECT 'flip'          , 'Flip'                                 UNION ALL
  SELECT 'bandiera'      , 'Bandiera'
)

SELECT DISTINCT
  r.name_with_owner                               AS repository_full_name,
  r.host_type                                     AS repository_host_type,
  COALESCE(r.size,0) * 1024                       AS repository_size_bytes,
  r.language                                      AS repository_primary_language,
  r.fork_source_name_with_owner                   AS repository_fork_source,
  r.updated_timestamp                             AS repository_last_update_utc,
  rd.dependency_project_name                      AS artifact_name_used,
  fl.library_name                                 AS feature_toggle_library_name,
  p.platform                                      AS library_platform,
  p.language                                      AS library_primary_language
FROM   `bigquery-public-data.libraries_io.repository_dependencies` rd
JOIN   feature_libs  fl
       ON LOWER(rd.dependency_project_name) LIKE CONCAT('%', fl.keyword, '%')
LEFT  JOIN `bigquery-public-data.libraries_io.repositories` r
       ON r.host_type         = rd.host_type
      AND r.name_with_owner   = rd.repository_name_with_owner
LEFT  JOIN `bigquery-public-data.libraries_io.projects` p
       ON p.id = rd.dependency_project_id
ORDER BY repository_full_name,
         artifact_name_used;