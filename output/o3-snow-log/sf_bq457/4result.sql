/* ---  Feature-toggle libraries list ------------------------------------ */
WITH FEATURE_TOGGLE_LIBS AS (
    SELECT *
    FROM VALUES
        ('NuGet'    , 'Unleash.FeatureToggle.Client'                 , 'unleash-client-dotnet'   , 'C#, Visual Basic'),
        ('NuGet'    , 'unleash.client'                               , 'unleash-client'          , 'C#, Visual Basic'),
        ('NuGet'    , 'LaunchDarkly.Client'                          , 'launchdarkly'            , 'C#, Visual Basic'),
        ('NuGet'    , 'NFeature'                                     , 'NFeature'                , 'C#, Visual Basic'),
        ('NuGet'    , 'FeatureToggle'                                , 'FeatureToggle'           , 'C#, Visual Basic'),
        ('NuGet'    , 'FeatureSwitcher'                              , 'FeatureSwitcher'         , 'C#, Visual Basic'),
        ('NuGet'    , 'Toggler'                                      , 'Toggler'                 , 'C#, Visual Basic'),
        ('Go'       , 'github.com/launchdarkly/go-client'            , 'launchdarkly'            , 'Go'),
        ('Go'       , 'github.com/xchapter7x/toggle'                 , 'Toggle'                  , 'Go'),
        ('Go'       , 'github.com/vsco/dcdr'                         , 'dcdr'                    , 'Go'),
        ('Go'       , 'github.com/unleash/unleash-client-go'         , 'unleash-client-go'       , 'Go'),
        ('NPM'      , 'unleash-client'                               , 'unleash-client-node'     , 'JavaScript, TypeScript'),
        ('NPM'      , 'ldclient-js'                                  , 'launchdarkly'            , 'JavaScript, TypeScript'),
        ('NPM'      , 'ember-feature-flags'                          , 'ember-feature-flags'     , 'JavaScript, TypeScript'),
        ('NPM'      , 'feature-toggles'                              , 'feature-toggles'         , 'JavaScript, TypeScript'),
        ('NPM'      , '@paralleldrive/react-feature-toggles'         , 'React Feature Toggles'   , 'JavaScript, TypeScript'),
        ('NPM'      , 'ldclient-node'                                , 'launchdarkly'            , 'JavaScript, TypeScript'),
        ('NPM'      , 'flipit'                                       , 'flipit'                  , 'JavaScript, TypeScript'),
        ('NPM'      , 'fflip'                                        , 'fflip'                   , 'JavaScript, TypeScript'),
        ('NPM'      , 'bandiera-client'                              , 'Bandiera'                , 'JavaScript, TypeScript'),
        ('NPM'      , '@flopflip/react-redux'                        , 'flopflip'                , 'JavaScript, TypeScript'),
        ('NPM'      , '@flopflip/react-broadcast'                    , 'flopflip'                , 'JavaScript, TypeScript'),
        ('Maven'    , 'com.launchdarkly:launchdarkly-android-client' , 'launchdarkly'            , 'Kotlin, Java'),
        ('Maven'    , 'cc.soham:toggle'                              , 'toggle'                  , 'Kotlin, Java'),
        ('Maven'    , 'no.finn.unleash:unleash-client-java'          , 'unleash-client-java'     , 'Kotlin, Java'),
        ('Maven'    , 'com.launchdarkly:launchdarkly-client'         , 'launchdarkly'            , 'Kotlin, Java'),
        ('Maven'    , 'org.togglz:togglz-core'                       , 'Togglz'                  , 'Kotlin, Java'),
        ('Maven'    , 'org.ff4j:ff4j-core'                           , 'FF4J'                    , 'Kotlin, Java'),
        ('Maven'    , 'com.tacitknowledge.flip:core'                 , 'Flip'                    , 'Kotlin, Java'),
        ('CocoaPods', 'LaunchDarkly'                                 , 'launchdarkly'            , 'Objective-C, Swift'),
        ('Carthage' , 'launchdarkly/ios-client'                      , 'launchdarkly'            , 'Objective-C, Swift'),
        ('Packagist', 'launchdarkly/launchdarkly-php'                , 'launchdarkly'            , 'PHP'),
        ('Packagist', 'dzunke/feature-flags-bundle'                  , 'Symfony FeatureFlagsBundle','PHP'),
        ('Packagist', 'opensoft/rollout'                             , 'rollout'                 , 'PHP'),
        ('Packagist', 'npg/bandiera-client-php'                      , 'Bandiera'                , 'PHP'),
        ('Pypi'     , 'UnleashClient'                                , 'unleash-client-python'   , 'Python'),
        ('Pypi'     , 'ldclient-py'                                  , 'launchdarkly'            , 'Python'),
        ('Pypi'     , 'Flask-FeatureFlags'                           , 'Flask FeatureFlags'      , 'Python'),
        ('Pypi'     , 'gutter'                                       , 'Gutter'                  , 'Python'),
        ('Pypi'     , 'feature_ramp'                                 , 'Feature Ramp'            , 'Python'),
        ('Pypi'     , 'flagon'                                       , 'flagon'                  , 'Python'),
        ('Pypi'     , 'django-waffle'                                , 'Waffle'                  , 'Python'),
        ('Pypi'     , 'gargoyle'                                     , 'Gargoyle'                , 'Python'),
        ('Pypi'     , 'gargoyle-yplan'                               , 'Gargoyle'                , 'Python'),
        ('Rubygems' , 'unleash'                                      , 'unleash-client-ruby'     , 'Ruby'),
        ('Rubygems' , 'ldclient-rb'                                  , 'launchdarkly'            , 'Ruby'),
        ('Rubygems' , 'rollout'                                      , 'rollout'                 , 'Ruby'),
        ('Rubygems' , 'feature_flipper'                              , 'FeatureFlipper'          , 'Ruby'),
        ('Rubygems' , 'flip'                                         , 'Flip'                    , 'Ruby'),
        ('Rubygems' , 'setler'                                       , 'Setler'                  , 'Ruby'),
        ('Rubygems' , 'bandiera-client'                              , 'Bandiera'                , 'Ruby'),
        ('Rubygems' , 'feature'                                      , 'Feature'                 , 'Ruby'),
        ('Rubygems' , 'flipper'                                      , 'Flipper'                 , 'Ruby'),
        ('Maven'    , 'com.springernature:bandiera-client-scala_2.12', 'Bandiera'                , 'Scala'),
        ('Maven'    , 'com.springernature:bandiera-client-scala_2.11', 'Bandiera'                , 'Scala')
        AS t(platform, artifact_name, library_name, library_languages)
)

/* ---  Repositories depending on those libraries ----------------------- */
SELECT DISTINCT
       r."name_with_owner"               AS "repository_full_name",
       r."host_type"                     AS "hosting_platform_type",
       r."size"                          AS "repository_size_bytes",
       r."language"                      AS "primary_language",
       r."fork_source_name_with_owner"   AS "fork_source_name_with_owner",
       r."updated_timestamp"             AS "repository_last_updated_timestamp",
       ft.artifact_name                  AS "feature_toggle_artifact_name",
       ft.library_name                   AS "feature_toggle_library_name",
       ft.library_languages              AS "feature_toggle_library_languages"
FROM   LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES rd
JOIN   FEATURE_TOGGLE_LIBS ft
       ON  LOWER(TRIM(rd."dependency_project_name")) = LOWER(TRIM(ft.artifact_name))
JOIN   LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES r
       ON  r."id" = rd."repository_id"
ORDER BY r."updated_timestamp" DESC NULLS LAST;