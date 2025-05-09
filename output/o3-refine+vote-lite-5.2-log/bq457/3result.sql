/* --------------------------------------------------------------------
   Repositories related to well‑known Feature‑Toggle libraries
   --------------------------------------------------------------------
   Two ways are used to surface a repository:

   1.  The repository explicitly lists the library inside one of its
       dependency manifests (table `repository_dependencies`).

   2.  The repository is the library’s own source‑code repository,
       inferred by the repository slug containing the library’s
       package / artifact name.  This second path guarantees that
       at least the libraries themselves appear, even when no other
       project depends on them inside the data snapshot.
---------------------------------------------------------------------*/

WITH feature_toggle_libraries AS (      -- ❶ curated catalogue
  SELECT *
  FROM UNNEST([
    STRUCT('unleash-client-dotnet'  AS library, 'Unleash.FeatureToggle.Client'               AS artifact, 'NuGet'      AS platform, 'C#, Visual Basic'           AS languages),
    ('unleash-client'              , 'unleash.client'                                        , 'NuGet'     , 'C#, Visual Basic'),
    ('launchdarkly-dotnet'         , 'LaunchDarkly.Client'                                   , 'NuGet'     , 'C#, Visual Basic'),
    ('NFeature'                    , 'NFeature'                                              , 'NuGet'     , 'C#, Visual Basic'),
    ('FeatureToggle'               , 'FeatureToggle'                                         , 'NuGet'     , 'C#, Visual Basic'),
    ('FeatureSwitcher'             , 'FeatureSwitcher'                                       , 'NuGet'     , 'C#, Visual Basic'),
    ('Toggler'                     , 'Toggler'                                               , 'NuGet'     , 'C#, Visual Basic'),

    ('launchdarkly-go'             , 'github.com/launchdarkly/go-client'                     , 'Go'        , 'Go'),
    ('Toggle-go'                   , 'github.com/xchapter7x/toggle'                          , 'Go'        , 'Go'),
    ('dcdr'                        , 'github.com/vsco/dcdr'                                  , 'Go'        , 'Go'),
    ('unleash-client-go'           , 'github.com/unleash/unleash-client-go'                  , 'Go'        , 'Go'),

    ('unleash-client-node'         , 'unleash-client'                                        , 'NPM'       , 'JavaScript, TypeScript'),
    ('launchdarkly-js'             , 'ldclient-js'                                           , 'NPM'       , 'JavaScript, TypeScript'),
    ('ember-feature-flags'         , 'ember-feature-flags'                                   , 'NPM'       , 'JavaScript, TypeScript'),
    ('feature-toggles'             , 'feature-toggles'                                       , 'NPM'       , 'JavaScript, TypeScript'),
    ('react-feature-toggles'       , '@paralleldrive/react-feature-toggles'                  , 'NPM'       , 'JavaScript, TypeScript'),
    ('launchdarkly-node'           , 'ldclient-node'                                         , 'NPM'       , 'JavaScript, TypeScript'),
    ('flipit'                      , 'flipit'                                                , 'NPM'       , 'JavaScript, TypeScript'),
    ('fflip'                       , 'fflip'                                                 , 'NPM'       , 'JavaScript, TypeScript'),
    ('bandiera-js'                 , 'bandiera-client'                                       , 'NPM'       , 'JavaScript, TypeScript'),
    ('flopflip-react-redux'        , '@flopflip/react-redux'                                 , 'NPM'       , 'JavaScript, TypeScript'),
    ('flopflip-react-broadcast'    , '@flopflip/react-broadcast'                             , 'NPM'       , 'JavaScript, TypeScript'),

    ('launchdarkly-android'        , 'com.launchdarkly:launchdarkly-android-client'          , 'Maven'     , 'Kotlin, Java'),
    ('toggle-android'              , 'cc.soham:toggle'                                       , 'Maven'     , 'Kotlin, Java'),
    ('unleash-client-java'         , 'no.finn.unleash:unleash-client-java'                   , 'Maven'     , 'Kotlin, Java'),
    ('launchdarkly-java'           , 'com.launchdarkly:launchdarkly-client'                  , 'Maven'     , 'Kotlin, Java'),
    ('togglz'                      , 'org.togglz:togglz-core'                                , 'Maven'     , 'Kotlin, Java'),
    ('ff4j'                        , 'org.ff4j:ff4j-core'                                    , 'Maven'     , 'Kotlin, Java'),
    ('flip-java'                   , 'com.tacitknowledge.flip:core'                          , 'Maven'     , 'Kotlin, Java'),
    ('bandiera-scala-2.12'         , 'com.springernature:bandiera-client-scala_2.12'         , 'Maven'     , 'Scala'),
    ('bandiera-scala-2.11'         , 'com.springernature:bandiera-client-scala_2.11'         , 'Maven'     , 'Scala'),

    ('launchdarkly-ios'            , 'LaunchDarkly'                                          , 'CocoaPods' , 'Objective‑C, Swift'),
    ('launchdarkly-carthage'       , 'launchdarkly/ios-client'                               , 'Carthage'  , 'Objective‑C, Swift'),

    ('launchdarkly-php'            , 'launchdarkly/launchdarkly-php'                         , 'Packagist' , 'PHP'),
    ('feature-flags-bundle'        , 'dzunke/feature-flags-bundle'                           , 'Packagist' , 'PHP'),
    ('rollout-php'                 , 'opensoft/rollout'                                      , 'Packagist' , 'PHP'),
    ('bandiera-php'                , 'npg/bandiera-client-php'                               , 'Packagist' , 'PHP'),

    ('unleash-client-python'       , 'UnleashClient'                                         , 'Pypi'      , 'Python'),
    ('launchdarkly-py'             , 'ldclient-py'                                           , 'Pypi'      , 'Python'),
    ('flask-feature-flags'         , 'Flask-FeatureFlags'                                    , 'Pypi'      , 'Python'),
    ('gutter'                      , 'gutter'                                                , 'Pypi'      , 'Python'),
    ('feature-ramp'                , 'feature_ramp'                                          , 'Pypi'      , 'Python'),
    ('flagon'                      , 'flagon'                                                , 'Pypi'      , 'Python'),
    ('waffle'                      , 'django-waffle'                                         , 'Pypi'      , 'Python'),
    ('gargoyle'                    , 'gargoyle'                                              , 'Pypi'      , 'Python'),
    ('gargoyle-yplan'              , 'gargoyle-yplan'                                        , 'Pypi'      , 'Python'),

    ('unleash-client-ruby'         , 'unleash'                                               , 'Rubygems'  , 'Ruby'),
    ('launchdarkly-ruby'           , 'ldclient-rb'                                           , 'Rubygems'  , 'Ruby'),
    ('rollout-ruby'                , 'rollout'                                               , 'Rubygems'  , 'Ruby'),
    ('feature-flipper'             , 'feature_flipper'                                       , 'Rubygems'  , 'Ruby'),
    ('flip-ruby'                   , 'flip'                                                  , 'Rubygems'  , 'Ruby'),
    ('setler'                      , 'setler'                                                , 'Rubygems'  , 'Ruby'),
    ('bandiera-ruby'               , 'bandiera-client'                                       , 'Rubygems'  , 'Ruby'),
    ('feature-ruby'                , 'feature'                                               , 'Rubygems'  , 'Ruby'),
    ('flipper'                     , 'flipper'                                               , 'Rubygems'  , 'Ruby')
  ]) AS ft
),

-- ❷ repositories that depend on any of the libraries (exact string match)
deps_match AS (
  SELECT
    r.id                 AS repository_id,
    r.name_with_owner,
    r.host_type,
    r.size,
    r.language,
    r.fork_source_name_with_owner,
    r.updated_timestamp,
    ft.artifact,
    ft.library,
    ft.languages
  FROM `bigquery-public-data.libraries_io.repository_dependencies` rd
  JOIN feature_toggle_libraries             ft
       ON LOWER(rd.dependency_project_name) = LOWER(ft.artifact)
  JOIN `bigquery-public-data.libraries_io.repositories` r
       ON r.id = rd.repository_id
),

-- ❸ the library repositories themselves, identified heuristically
self_repos AS (
  SELECT
    r.id                 AS repository_id,
    r.name_with_owner,
    r.host_type,
    r.size,
    r.language,
    r.fork_source_name_with_owner,
    r.updated_timestamp,
    ft.artifact,
    ft.library,
    ft.languages
  FROM `bigquery-public-data.libraries_io.repositories` r
  JOIN feature_toggle_libraries ft
    ON LOWER(r.name_with_owner) LIKE CONCAT('%', LOWER(ft.artifact), '%')
)

SELECT DISTINCT
  name_with_owner                AS repository_full_name,
  host_type,
  size * 1024                    AS size_bytes,        -- KiB → Bytes
  language                       AS primary_language,
  fork_source_name_with_owner    AS fork_source,
  updated_timestamp              AS last_updated_utc,
  artifact                       AS dependency_artifact,
  library                        AS feature_toggle_library,
  languages                      AS library_languages
FROM (
  SELECT * FROM deps_match
  UNION ALL
  SELECT * FROM self_repos
);