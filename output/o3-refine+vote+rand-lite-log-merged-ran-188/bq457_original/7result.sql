/* ----------------------------------------------------------------------------
   Repositories that declare at least one well‑known feature‑toggle library
   (detected in any manifest / lock‑file captured by Libraries.io)
--------------------------------------------------------------------------- */

WITH feature_toggle_libs AS (
  -- Canonical list of package / artifact names for feature‑toggle libraries
  SELECT * FROM UNNEST ([
    -- .NET
    STRUCT('unleash.featuretoggle.client' AS dep_name , 'unleash-client-dotnet'  AS library , 'C#, Visual Basic'            AS lib_langs),
    STRUCT('unleash.client'              , 'unleash-client'          , 'C#, Visual Basic'),
    STRUCT('launchdarkly.client'         , 'launchdarkly'            , 'C#, Visual Basic'),
    STRUCT('nfeature'                    , 'NFeature'                , 'C#, Visual Basic'),
    STRUCT('featuretoggle'               , 'FeatureToggle'           , 'C#, Visual Basic'),
    STRUCT('featureswitcher'             , 'FeatureSwitcher'         , 'C#, Visual Basic'),
    STRUCT('toggler'                     , 'Toggler'                 , 'C#, Visual Basic'),

    -- Go
    STRUCT('github.com/launchdarkly/go-client'      , 'launchdarkly'        , 'Go'),
    STRUCT('github.com/xchapter7x/toggle'           , 'Toggle'              , 'Go'),
    STRUCT('github.com/vsco/dcdr'                   , 'dcdr'                , 'Go'),
    STRUCT('github.com/unleash/unleash-client-go'   , 'unleash-client-go'   , 'Go'),

    -- JavaScript / TypeScript
    STRUCT('unleash-client'                         , 'unleash-client-node' , 'JavaScript, TypeScript'),
    STRUCT('ldclient-js'                            , 'launchdarkly'        , 'JavaScript, TypeScript'),
    STRUCT('ember-feature-flags'                    , 'ember-feature-flags' , 'JavaScript, TypeScript'),
    STRUCT('feature-toggles'                        , 'feature-toggles'     , 'JavaScript, TypeScript'),
    STRUCT('@paralleldrive/react-feature-toggles'   , 'React Feature Toggles','JavaScript, TypeScript'),
    STRUCT('ldclient-node'                          , 'launchdarkly'        , 'JavaScript, TypeScript'),
    STRUCT('flipit'                                 , 'flipit'              , 'JavaScript, TypeScript'),
    STRUCT('fflip'                                  , 'fflip'               , 'JavaScript, TypeScript'),
    STRUCT('bandiera-client'                        , 'Bandiera'            , 'JavaScript, TypeScript'),
    STRUCT('@flopflip/react-redux'                  , 'flopflip'            , 'JavaScript, TypeScript'),
    STRUCT('@flopflip/react-broadcast'              , 'flopflip'            , 'JavaScript, TypeScript'),

    -- Kotlin / Java (Maven/Gradle coords)
    STRUCT('com.launchdarkly:launchdarkly-android-client', 'launchdarkly'    , 'Kotlin, Java'),
    STRUCT('cc.soham:toggle'                            , 'toggle'          , 'Kotlin, Java'),
    STRUCT('no.finn.unleash:unleash-client-java'        , 'unleash-client-java','Kotlin, Java'),
    STRUCT('com.launchdarkly:launchdarkly-client'       , 'launchdarkly'    , 'Kotlin, Java'),
    STRUCT('org.togglz:togglz-core'                     , 'Togglz'          , 'Kotlin, Java'),
    STRUCT('org.ff4j:ff4j-core'                         , 'FF4J'            , 'Kotlin, Java'),
    STRUCT('com.tacitknowledge.flip:core'               , 'Flip'            , 'Kotlin, Java'),

    -- iOS / CocoaPods / Carthage
    STRUCT('launchdarkly'                               , 'launchdarkly'    , 'Objective‑C, Swift'),
    STRUCT('launchdarkly/ios-client'                    , 'launchdarkly'    , 'Objective‑C, Swift'),

    -- PHP
    STRUCT('launchdarkly/launchdarkly-php'              , 'launchdarkly'    , 'PHP'),
    STRUCT('dzunke/feature-flags-bundle'                , 'Symfony FeatureFlagsBundle', 'PHP'),
    STRUCT('opensoft/rollout'                           , 'rollout'         , 'PHP'),
    STRUCT('npg/bandiera-client-php'                    , 'Bandiera'        , 'PHP'),

    -- Python
    STRUCT('unleashclient'                              , 'unleash-client-python', 'Python'),
    STRUCT('ldclient-py'                                , 'launchdarkly'    , 'Python'),
    STRUCT('flask-featureflags'                         , 'Flask FeatureFlags', 'Python'),
    STRUCT('gutter'                                     , 'Gutter'          , 'Python'),
    STRUCT('feature_ramp'                               , 'Feature Ramp'    , 'Python'),
    STRUCT('flagon'                                     , 'flagon'          , 'Python'),
    STRUCT('django-waffle'                              , 'Waffle'          , 'Python'),
    STRUCT('gargoyle'                                   , 'Gargoyle'        , 'Python'),
    STRUCT('gargoyle-yplan'                             , 'Gargoyle'        , 'Python'),

    -- Ruby
    STRUCT('unleash'                                    , 'unleash-client-ruby', 'Ruby'),
    STRUCT('ldclient-rb'                                , 'launchdarkly'    , 'Ruby'),
    STRUCT('rollout'                                    , 'rollout'         , 'Ruby'),
    STRUCT('feature_flipper'                            , 'FeatureFlipper'  , 'Ruby'),
    STRUCT('flip'                                       , 'Flip'            , 'Ruby'),
    STRUCT('setler'                                     , 'Setler'          , 'Ruby'),
    STRUCT('bandiera-client'                            , 'Bandiera'        , 'Ruby'),
    STRUCT('feature'                                    , 'Feature'         , 'Ruby'),
    STRUCT('flipper'                                    , 'Flipper'         , 'Ruby'),

    -- Scala
    STRUCT('com.springernature:bandiera-client-scala_2.12','Bandiera'       , 'Scala'),
    STRUCT('com.springernature:bandiera-client-scala_2.11','Bandiera'       , 'Scala')
  ])
)

SELECT DISTINCT
  r.name_with_owner                    AS repository_full_name,
  r.host_type                          AS hosting_platform,
  SAFE_MULTIPLY(r.size, 1024)          AS size_bytes,
  r.language                           AS primary_language,
  r.fork_source_name_with_owner        AS fork_source,
  r.updated_timestamp                  AS repository_last_update,
  d.dependency_project_name            AS artifact_name,
  f.library                            AS library_name,
  f.lib_langs                          AS library_languages
FROM  `bigquery-public-data.libraries_io.repository_dependencies`  AS d
JOIN  feature_toggle_libs f
      ON  LOWER(d.dependency_project_name) = f.dep_name
LEFT JOIN `bigquery-public-data.libraries_io.repositories`         AS r
      ON  r.id = d.repository_id
ORDER BY
  repository_full_name,
  artifact_name;