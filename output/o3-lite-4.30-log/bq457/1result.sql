/* Repositories that depend on one of the selected feature‑toggle libraries */
WITH feature_toggle_libraries AS (
  SELECT *
  FROM UNNEST([
    STRUCT('unleash-client'                                AS artifact, 'Unleash'        AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('unleash.client'                                AS artifact, 'Unleash'        AS library_name, '.NET'                    AS library_languages),
    STRUCT('Unleash.FeatureToggle.Client'                  AS artifact, 'Unleash'        AS library_name, '.NET'                    AS library_languages),
    STRUCT('unleash-client-go'                             AS artifact, 'Unleash'        AS library_name, 'Go'                      AS library_languages),
    STRUCT('github.com/unleash/unleash-client-go'          AS artifact, 'Unleash'        AS library_name, 'Go'                      AS library_languages),
    STRUCT('no.finn.unleash:unleash-client-java'           AS artifact, 'Unleash'        AS library_name, 'Java / Kotlin'           AS library_languages),
    STRUCT('UnleashClient'                                 AS artifact, 'Unleash'        AS library_name, 'Python'                  AS library_languages),
    STRUCT('unleash'                                       AS artifact, 'Unleash'        AS library_name, 'Ruby'                    AS library_languages),

    STRUCT('ldclient-js'                                   AS artifact, 'LaunchDarkly'   AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('ldclient-node'                                 AS artifact, 'LaunchDarkly'   AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('LaunchDarkly.Client'                           AS artifact, 'LaunchDarkly'   AS library_name, '.NET'                    AS library_languages),
    STRUCT('com.launchdarkly:launchdarkly-android-client'  AS artifact, 'LaunchDarkly'   AS library_name, 'Java / Kotlin'           AS library_languages),
    STRUCT('com.launchdarkly:launchdarkly-client'          AS artifact, 'LaunchDarkly'   AS library_name, 'Java / Kotlin'           AS library_languages),
    STRUCT('LaunchDarkly'                                  AS artifact, 'LaunchDarkly'   AS library_name, 'Objective‑C / Swift'     AS library_languages),
    STRUCT('launchdarkly/ios-client'                       AS artifact, 'LaunchDarkly'   AS library_name, 'Objective‑C / Swift'     AS library_languages),
    STRUCT('launchdarkly/launchdarkly-php'                 AS artifact, 'LaunchDarkly'   AS library_name, 'PHP'                     AS library_languages),
    STRUCT('ldclient-py'                                   AS artifact, 'LaunchDarkly'   AS library_name, 'Python'                  AS library_languages),
    STRUCT('ldclient-rb'                                   AS artifact, 'LaunchDarkly'   AS library_name, 'Ruby'                    AS library_languages),
    STRUCT('github.com/launchdarkly/go-client'             AS artifact, 'LaunchDarkly'   AS library_name, 'Go'                      AS library_languages),

    STRUCT('feature-toggles'                               AS artifact, 'feature-toggles'AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('@paralleldrive/react-feature-toggles'          AS artifact, 'feature-toggles'AS library_name, 'JavaScript / TypeScript' AS library_languages),

    STRUCT('FeatureToggle'                                 AS artifact, 'FeatureToggle'  AS library_name, '.NET'                    AS library_languages),
    STRUCT('FeatureSwitcher'                               AS artifact, 'FeatureSwitcher'AS library_name, '.NET'                    AS library_languages),
    STRUCT('Toggler'                                       AS artifact, 'Toggler'        AS library_name, '.NET'                    AS library_languages),
    STRUCT('NFeature'                                      AS artifact, 'NFeature'       AS library_name, '.NET'                    AS library_languages),

    STRUCT('@flopflip/react-redux'                         AS artifact, 'flopflip'       AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('@flopflip/react-broadcast'                     AS artifact, 'flopflip'       AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('fflip'                                         AS artifact, 'fflip'          AS library_name, 'JavaScript / TypeScript' AS library_languages),
    STRUCT('flipit'                                        AS artifact, 'flipit'         AS library_name, 'JavaScript / TypeScript' AS library_languages),

    STRUCT('flipper'                                       AS artifact, 'Flipper'        AS library_name, 'Ruby'                    AS library_languages),
    STRUCT('flip'                                          AS artifact, 'Flip'           AS library_name, 'Ruby'                    AS library_languages),

    STRUCT('bandiera-client'                               AS artifact, 'Bandiera'       AS library_name, 'Ruby'                    AS library_languages),
    STRUCT('bandiera-client-php'                           AS artifact, 'Bandiera'       AS library_name, 'PHP'                     AS library_languages),
    STRUCT('com.springernature:bandiera-client-scala_2.12' AS artifact, 'Bandiera'       AS library_name, 'Scala'                   AS library_languages),
    STRUCT('com.springernature:bandiera-client-scala_2.11' AS artifact, 'Bandiera'       AS library_name, 'Scala'                   AS library_languages),

    STRUCT('org.togglz:togglz-core'                        AS artifact, 'Togglz'         AS library_name, 'Java'                    AS library_languages),
    STRUCT('org.ff4j:ff4j-core'                            AS artifact, 'FF4J'           AS library_name, 'Java'                    AS library_languages),
    STRUCT('cc.soham:toggle'                               AS artifact, 'toggle'         AS library_name, 'Java / Kotlin'           AS library_languages),
    STRUCT('toggle'                                        AS artifact, 'toggle'         AS library_name, 'Go / other'              AS library_languages),
    STRUCT('github.com/xchapter7x/toggle'                  AS artifact, 'toggle'         AS library_name, 'Go'                      AS library_languages),
    STRUCT('github.com/vsco/dcdr'                          AS artifact, 'dcdr'           AS library_name, 'Go'                      AS library_languages),

    STRUCT('rollout'                                       AS artifact, 'rollout'        AS library_name, 'Ruby'                    AS library_languages),
    STRUCT('opensoft/rollout'                              AS artifact, 'rollout'        AS library_name, 'PHP'                     AS library_languages),

    STRUCT('gutter'                                        AS artifact, 'Gutter'         AS library_name, 'Python'                  AS library_languages),
    STRUCT('django-waffle'                                 AS artifact, 'Waffle'         AS library_name, 'Python'                  AS library_languages),
    STRUCT('gargoyle'                                      AS artifact, 'Gargoyle'       AS library_name, 'Python'                  AS library_languages),
    STRUCT('gargoyle-yplan'                                AS artifact, 'Gargoyle'       AS library_name, 'Python'                  AS library_languages),
    STRUCT('feature_ramp'                                  AS artifact, 'Feature Ramp'   AS library_name, 'Python'                  AS library_languages),
    STRUCT('flagon'                                        AS artifact, 'flagon'         AS library_name, 'Python'                  AS library_languages),
    STRUCT('Flask-FeatureFlags'                            AS artifact, 'Flask FeatureFlags' AS library_name, 'Python'              AS library_languages)
  ])
)

SELECT DISTINCT
  r.name_with_owner             AS repo_full_name_with_owner,
  r.host_type                   AS hosting_platform_type,
  r.size * 1024                 AS size_bytes,
  r.language                    AS primary_language,
  r.fork_source_name_with_owner AS fork_source_name,
  r.updated_timestamp           AS last_update_timestamp,
  f.artifact                    AS feature_toggle_artifact,
  f.library_name                AS feature_toggle_library_name,
  f.library_languages           AS feature_toggle_library_languages
FROM `bigquery-public-data.libraries_io.repository_dependencies` AS rd
JOIN feature_toggle_libraries                                   AS f
  ON rd.dependency_project_name = f.artifact
JOIN `bigquery-public-data.libraries_io.repositories`           AS r
  ON rd.repository_id = r.id
ORDER BY repo_full_name_with_owner;