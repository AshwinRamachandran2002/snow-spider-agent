/*  Repositories that rely on well-known feature-toggle / feature-flag
    libraries (LaunchDarkly, Unleash, Togglz, etc.).                   */

SELECT DISTINCT
  rd.repository_name_with_owner                         AS name_with_owner,
  COALESCE(r.host_type, rd.host_type)                   AS host_type,
  r.size * 1024                                         AS size_bytes,
  r.language                                            AS primary_language,
  r.fork_source_name_with_owner                         AS fork_source_name_with_owner,
  r.updated_timestamp                                   AS repository_last_update,
  libs.artifact                                         AS dependency_artifact,
  libs.library                                          AS feature_toggle_library,
  libs.languages                                        AS library_languages
FROM `bigquery-public-data.libraries_io.repository_dependencies` AS rd
LEFT JOIN `bigquery-public-data.libraries_io.repositories`        AS r
       ON rd.repository_name_with_owner = r.name_with_owner
JOIN UNNEST([
  --  .NET / NuGet ------------------------------------------------------------
  STRUCT('Unleash'          AS library, 'Unleash.FeatureToggle.Client'               AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('Unleash'          AS library, 'unleash.client'                             AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('LaunchDarkly'     AS library, 'LaunchDarkly.Client'                        AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('NFeature'         AS library, 'NFeature'                                   AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('FeatureToggle'    AS library, 'FeatureToggle'                              AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('FeatureSwitcher'  AS library, 'FeatureSwitcher'                            AS artifact, 'C#, Visual Basic'          AS languages),
  STRUCT('Toggler'          AS library, 'Toggler'                                    AS artifact, 'C#, Visual Basic'          AS languages),

  --  Go ----------------------------------------------------------------------
  STRUCT('LaunchDarkly'     AS library, 'github.com/launchdarkly/go-client'          AS artifact, 'Go'                        AS languages),
  STRUCT('Toggle'           AS library, 'github.com/xchapter7x/toggle'               AS artifact, 'Go'                        AS languages),
  STRUCT('DCDR'             AS library, 'github.com/vsco/dcdr'                       AS artifact, 'Go'                        AS languages),
  STRUCT('Unleash'          AS library, 'github.com/unleash/unleash-client-go'       AS artifact, 'Go'                        AS languages),

  --  JavaScript / TypeScript -------------------------------------------------
  STRUCT('Unleash'          AS library, 'unleash-client'                             AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('LaunchDarkly'     AS library, 'ldclient-js'                                AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('Ember Feature Flags' AS library, 'ember-feature-flags'                     AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('feature-toggles'  AS library, 'feature-toggles'                            AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('React Feature Toggles' AS library, '@paralleldrive/react-feature-toggles'  AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('LaunchDarkly'     AS library, 'ldclient-node'                              AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('flipit'           AS library, 'flipit'                                     AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('fflip'            AS library, 'fflip'                                      AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('Bandiera'         AS library, 'bandiera-client'                            AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('flopflip'         AS library, '@flopflip/react-redux'                      AS artifact, 'JavaScript, TypeScript'    AS languages),
  STRUCT('flopflip'         AS library, '@flopflip/react-broadcast'                  AS artifact, 'JavaScript, TypeScript'    AS languages),

  --  Maven / Kotlin / Java ---------------------------------------------------
  STRUCT('LaunchDarkly'     AS library, 'com.launchdarkly:launchdarkly-android-client' AS artifact, 'Kotlin, Java'           AS languages),
  STRUCT('Toggle'           AS library, 'cc.soham:toggle'                            AS artifact, 'Kotlin, Java'             AS languages),
  STRUCT('Unleash'          AS library, 'no.finn.unleash:unleash-client-java'        AS artifact, 'Kotlin, Java'             AS languages),
  STRUCT('LaunchDarkly'     AS library, 'com.launchdarkly:launchdarkly-client'       AS artifact, 'Kotlin, Java'             AS languages),
  STRUCT('Togglz'           AS library, 'org.togglz:togglz-core'                     AS artifact, 'Kotlin, Java'             AS languages),
  STRUCT('FF4J'             AS library, 'org.ff4j:ff4j-core'                         AS artifact, 'Kotlin, Java'             AS languages),
  STRUCT('Flip'             AS library, 'com.tacitknowledge.flip:core'               AS artifact, 'Kotlin, Java'             AS languages),

  --  iOS / CocoaPods / Carthage ---------------------------------------------
  STRUCT('LaunchDarkly'     AS library, 'LaunchDarkly'                               AS artifact, 'Objective-C, Swift'        AS languages),
  STRUCT('LaunchDarkly'     AS library, 'launchdarkly/ios-client'                    AS artifact, 'Objective-C, Swift'        AS languages),

  --  PHP / Packagist ---------------------------------------------------------
  STRUCT('LaunchDarkly'     AS library, 'launchdarkly/launchdarkly-php'              AS artifact, 'PHP'                       AS languages),
  STRUCT('Symfony FeatureFlagsBundle' AS library, 'dzunke/feature-flags-bundle'      AS artifact, 'PHP'                       AS languages),
  STRUCT('Rollout'          AS library, 'opensoft/rollout'                           AS artifact, 'PHP'                       AS languages),
  STRUCT('Bandiera'         AS library, 'npg/bandiera-client-php'                    AS artifact, 'PHP'                       AS languages),

  --  Python / PyPI -----------------------------------------------------------
  STRUCT('Unleash'          AS library, 'UnleashClient'                              AS artifact, 'Python'                    AS languages),
  STRUCT('LaunchDarkly'     AS library, 'ldclient-py'                                AS artifact, 'Python'                    AS languages),
  STRUCT('Flask FeatureFlags' AS library, 'Flask-FeatureFlags'                       AS artifact, 'Python'                    AS languages),
  STRUCT('Gutter'           AS library, 'gutter'                                     AS artifact, 'Python'                    AS languages),
  STRUCT('Feature Ramp'     AS library, 'feature_ramp'                               AS artifact, 'Python'                    AS languages),
  STRUCT('flagon'           AS library, 'flagon'                                     AS artifact, 'Python'                    AS languages),
  STRUCT('Waffle'           AS library, 'django-waffle'                              AS artifact, 'Python'                    AS languages),
  STRUCT('Gargoyle'         AS library, 'gargoyle'                                   AS artifact, 'Python'                    AS languages),
  STRUCT('Gargoyle'         AS library, 'gargoyle-yplan'                             AS artifact, 'Python'                    AS languages),

  --  Ruby / Rubygems ---------------------------------------------------------
  STRUCT('Unleash'          AS library, 'unleash'                                    AS artifact, 'Ruby'                      AS languages),
  STRUCT('LaunchDarkly'     AS library, 'ldclient-rb'                                AS artifact, 'Ruby'                      AS languages),
  STRUCT('Rollout'          AS library, 'rollout'                                    AS artifact, 'Ruby'                      AS languages),
  STRUCT('FeatureFlipper'   AS library, 'feature_flipper'                            AS artifact, 'Ruby'                      AS languages),
  STRUCT('Flip'             AS library, 'flip'                                       AS artifact, 'Ruby'                      AS languages),
  STRUCT('Setler'           AS library, 'setler'                                     AS artifact, 'Ruby'                      AS languages),
  STRUCT('Bandiera'         AS library, 'bandiera-client'                            AS artifact, 'Ruby'                      AS languages),
  STRUCT('Feature'          AS library, 'feature'                                    AS artifact, 'Ruby'                      AS languages),
  STRUCT('Flipper'          AS library, 'flipper'                                    AS artifact, 'Ruby'                      AS languages),

  --  Scala / Maven -----------------------------------------------------------
  STRUCT('Bandiera'         AS library, 'com.springernature:bandiera-client-scala_2.12' AS artifact, 'Scala'                 AS languages),
  STRUCT('Bandiera'         AS library, 'com.springernature:bandiera-client-scala_2.11' AS artifact, 'Scala'                 AS languages)
]) AS libs
  ON LOWER(rd.dependency_project_name) LIKE CONCAT('%', LOWER(libs.artifact), '%');