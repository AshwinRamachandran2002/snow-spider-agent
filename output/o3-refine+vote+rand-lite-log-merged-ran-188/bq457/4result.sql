-- Repositories that make use of well-known Feature-Toggle libraries
WITH feature_toggle_deps AS (
  SELECT
    rd.repository_name_with_owner,
    rd.dependency_project_id,
    rd.dependency_project_name
  FROM `bigquery-public-data.libraries_io.repository_dependencies` rd
  -- Any dependency whose project name matches one of the common feature-toggle libraries
  WHERE REGEXP_CONTAINS(
          LOWER(rd.dependency_project_name),
          r'(launchdarkly|unleash|togglz|ff4j|flipper|waffle|bandiera|gargoyle|flipit|fflip|feature[_\-]?toggle(s)?|feature[_\-]?switcher|react-feature-toggles|toggler|nfeature|flagon|feature_ramp|rollout|dcdr|gutter|setler)'
        )
)

SELECT
  repo.name_with_owner                 AS repository_full_name,
  repo.host_type                       AS hosting_platform,
  repo.size * 1024                     AS repository_size_bytes,
  repo.language                        AS repository_primary_language,
  repo.fork_source_name_with_owner     AS fork_source_name,
  repo.updated_timestamp               AS repository_last_update,
  proj.name                            AS feature_toggle_artifact,
  proj.platform                        AS artifact_platform,
  proj.language                        AS feature_toggle_language
FROM feature_toggle_deps            AS ftd
LEFT JOIN `bigquery-public-data.libraries_io.repositories` repo
       ON repo.name_with_owner = ftd.repository_name_with_owner          -- repository details
LEFT JOIN `bigquery-public-data.libraries_io.projects`     proj
       ON proj.id               = ftd.dependency_project_id              -- library (artifact) details
ORDER BY
  repository_full_name,
  feature_toggle_artifact;