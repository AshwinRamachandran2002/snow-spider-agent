WITH library_map AS (
    SELECT column1 AS artifact ,
           column2 AS library_name ,
           column3 AS library_languages
    FROM VALUES
        ('unleash-client'                               , 'unleash-client-node'      , 'JavaScript, TypeScript'),
        ('ldclient-js'                                  , 'launchdarkly'             , 'JavaScript, TypeScript'),
        ('ember-feature-flags'                          , 'ember-feature-flags'      , 'JavaScript, TypeScript'),
        ('feature-toggles'                              , 'feature-toggles'          , 'JavaScript, TypeScript'),
        ('@paralleldrive/react-feature-toggles'         , 'React Feature Toggles'    , 'JavaScript, TypeScript'),
        ('ldclient-node'                                , 'launchdarkly'             , 'JavaScript, TypeScript'),
        ('flipit'                                       , 'flipit'                   , 'JavaScript, TypeScript'),
        ('fflip'                                        , 'fflip'                    , 'JavaScript, TypeScript'),
        ('bandiera-client'                              , 'Bandiera'                 , 'JavaScript, TypeScript'),
        ('@flopflip/react-redux'                        , 'flopflip'                 , 'JavaScript, TypeScript'),
        ('@flopflip/react-broadcast'                    , 'flopflip'                 , 'JavaScript, TypeScript'),
        ('Unleash.FeatureToggle.Client'                 , 'unleash-client-dotnet'    , 'C#, Visual Basic'),
        ('unleash.client'                               , 'unleash-client'           , 'C#, Visual Basic'),
        ('LaunchDarkly.Client'                          , 'launchdarkly'             , 'C#, Visual Basic'),
        ('NFeature'                                     , 'NFeature'                 , 'C#, Visual Basic'),
        ('FeatureToggle'                                , 'FeatureToggle'            , 'C#, Visual Basic'),
        ('FeatureSwitcher'                              , 'FeatureSwitcher'          , 'C#, Visual Basic'),
        ('Toggler'                                      , 'Toggler'                  , 'C#, Visual Basic'),
        ('github.com/launchdarkly/go-client'            , 'launchdarkly'             , 'Go'),
        ('github.com/xchapter7x/toggle'                 , 'Toggle'                   , 'Go'),
        ('github.com/vsco/dcdr'                         , 'dcdr'                     , 'Go'),
        ('github.com/unleash/unleash-client-go'         , 'unleash-client-go'        , 'Go'),
        ('com.launchdarkly:launchdarkly-android-client' , 'launchdarkly'             , 'Kotlin, Java'),
        ('cc.soham:toggle'                              , 'toggle'                   , 'Kotlin, Java'),
        ('no.finn.unleash:unleash-client-java'          , 'unleash-client-java'      , 'Kotlin, Java'),
        ('com.launchdarkly:launchdarkly-client'         , 'launchdarkly'             , 'Kotlin, Java'),
        ('org.togglz:togglz-core'                       , 'Togglz'                   , 'Kotlin, Java'),
        ('org.ff4j:ff4j-core'                           , 'FF4J'                     , 'Kotlin, Java'),
        ('com.tacitknowledge.flip:core'                 , 'Flip'                     , 'Kotlin, Java'),
        ('LaunchDarkly'                                 , 'launchdarkly'             , 'Objective-C, Swift'),
        ('launchdarkly/ios-client'                      , 'launchdarkly'             , 'Objective-C, Swift'),
        ('launchdarkly/launchdarkly-php'                , 'launchdarkly'             , 'PHP'),
        ('dzunke/feature-flags-bundle'                  , 'Symfony FeatureFlagsBundle', 'PHP'),
        ('opensoft/rollout'                             , 'rollout'                  , 'PHP'),
        ('npg/bandiera-client-php'                      , 'Bandiera'                 , 'PHP'),
        ('UnleashClient'                                , 'unleash-client-python'    , 'Python'),
        ('ldclient-py'                                  , 'launchdarkly'             , 'Python'),
        ('Flask-FeatureFlags'                           , 'Flask FeatureFlags'       , 'Python'),
        ('gutter'                                       , 'Gutter'                   , 'Python'),
        ('feature_ramp'                                 , 'Feature Ramp'             , 'Python'),
        ('flagon'                                       , 'flagon'                   , 'Python'),
        ('django-waffle'                                , 'Waffle'                   , 'Python'),
        ('gargoyle'                                     , 'Gargoyle'                 , 'Python'),
        ('gargoyle-yplan'                               , 'Gargoyle'                 , 'Python'),
        ('unleash'                                      , 'unleash-client-ruby'      , 'Ruby'),
        ('ldclient-rb'                                  , 'launchdarkly'             , 'Ruby'),
        ('rollout'                                      , 'rollout'                  , 'Ruby'),
        ('feature_flipper'                              , 'FeatureFlipper'           , 'Ruby'),
        ('flip'                                         , 'Flip'                     , 'Ruby'),
        ('setler'                                       , 'Setler'                   , 'Ruby'),
        ('bandiera-client'                              , 'Bandiera'                 , 'Ruby'),
        ('feature'                                      , 'Feature'                  , 'Ruby'),
        ('flipper'                                      , 'Flipper'                  , 'Ruby'),
        ('com.springernature:bandiera-client-scala_2.12', 'Bandiera'                 , 'Scala'),
        ('com.springernature:bandiera-client-scala_2.11', 'Bandiera'                 , 'Scala')
),
filtered_deps AS (
    SELECT
        rd."repository_id",
        rd."dependency_project_name"          AS artifact_name,
        lm.library_name,
        lm.library_languages
    FROM LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES rd
    JOIN library_map lm
      ON LOWER(rd."dependency_project_name") = LOWER(lm.artifact)
)
SELECT
    r."name_with_owner"               AS repository_full_name,
    r."host_type"                     AS repository_host_type,
    r."size"                          AS repository_size_bytes,
    r."language"                      AS repository_primary_language,
    r."fork_source_name_with_owner"   AS repository_fork_source,
    r."updated_timestamp"             AS repository_updated_timestamp,
    d.artifact_name                   AS dependency_artifact_name,
    d.library_name,
    d.library_languages
FROM filtered_deps d
JOIN LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES r
  ON d."repository_id" = r."id"
ORDER BY r."updated_timestamp" DESC NULLS LAST;