SELECT
    r."name_with_owner"                                 AS repository_full_name_with_owner,
    r."host_type",
    r."size",
    r."language",
    r."fork_source_name_with_owner",
    r."updated_timestamp",
    rd."dependency_project_name"                       AS artifact_name,
    /* map artifact -> library name */
    CASE
        WHEN rd."dependency_project_name" = 'Unleash.FeatureToggle.Client'            THEN 'unleash-client-dotnet'
        WHEN rd."dependency_project_name" = 'unleash.client'                          THEN 'unleash-client'
        WHEN rd."dependency_project_name" = 'LaunchDarkly.Client'                     THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'NFeature'                                THEN 'NFeature'
        WHEN rd."dependency_project_name" = 'FeatureToggle'                           THEN 'FeatureToggle'
        WHEN rd."dependency_project_name" = 'FeatureSwitcher'                         THEN 'FeatureSwitcher'
        WHEN rd."dependency_project_name" = 'Toggler'                                 THEN 'Toggler'
        WHEN rd."dependency_project_name" = 'github.com/launchdarkly/go-client'       THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'github.com/xchapter7x/toggle'            THEN 'Toggle'
        WHEN rd."dependency_project_name" = 'github.com/vsco/dcdr'                    THEN 'dcdr'
        WHEN rd."dependency_project_name" = 'github.com/unleash/unleash-client-go'    THEN 'unleash-client-go'
        WHEN rd."dependency_project_name" = 'unleash-client'                          THEN 'unleash-client-node'
        WHEN rd."dependency_project_name" = 'ldclient-js'                             THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'ember-feature-flags'                     THEN 'ember-feature-flags'
        WHEN rd."dependency_project_name" = 'feature-toggles'                         THEN 'feature-toggles'
        WHEN rd."dependency_project_name" = '@paralleldrive/react-feature-toggles'    THEN 'React Feature Toggles'
        WHEN rd."dependency_project_name" = 'ldclient-node'                           THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'flipit'                                  THEN 'flipit'
        WHEN rd."dependency_project_name" = 'fflip'                                   THEN 'fflip'
        WHEN rd."dependency_project_name" = 'bandiera-client'                         THEN 'Bandiera'
        WHEN rd."dependency_project_name" = '@flopflip/react-redux'                   THEN 'flopflip'
        WHEN rd."dependency_project_name" = '@flopflip/react-broadcast'               THEN 'flopflip'
        WHEN rd."dependency_project_name" = 'com.launchdarkly:launchdarkly-android-client' THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'cc.soham:toggle'                         THEN 'toggle'
        WHEN rd."dependency_project_name" = 'no.finn.unleash:unleash-client-java'     THEN 'unleash-client-java'
        WHEN rd."dependency_project_name" = 'com.launchdarkly:launchdarkly-client'    THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'org.togglz:togglz-core'                  THEN 'Togglz'
        WHEN rd."dependency_project_name" = 'org.ff4j:ff4j-core'                      THEN 'FF4J'
        WHEN rd."dependency_project_name" = 'com.tacitknowledge.flip:core'            THEN 'Flip'
        WHEN rd."dependency_project_name" = 'com.springernature:bandiera-client-scala_2.12' THEN 'Bandiera'
        WHEN rd."dependency_project_name" = 'com.springernature:bandiera-client-scala_2.11' THEN 'Bandiera'
        WHEN rd."dependency_project_name" = 'launchdarkly/launchdarkly-php'           THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'dzunke/feature-flags-bundle'             THEN 'Symfony FeatureFlagsBundle'
        WHEN rd."dependency_project_name" = 'opensoft/rollout'                        THEN 'rollout'
        WHEN rd."dependency_project_name" = 'npg/bandiera-client-php'                 THEN 'Bandiera'
        WHEN rd."dependency_project_name" = 'UnleashClient'                           THEN 'unleash-client-python'
        WHEN rd."dependency_project_name" = 'ldclient-py'                             THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'Flask-FeatureFlags'                      THEN 'Flask FeatureFlags'
        WHEN rd."dependency_project_name" = 'gutter'                                  THEN 'Gutter'
        WHEN rd."dependency_project_name" = 'feature_ramp'                            THEN 'Feature Ramp'
        WHEN rd."dependency_project_name" = 'flagon'                                  THEN 'flagon'
        WHEN rd."dependency_project_name" = 'django-waffle'                           THEN 'Waffle'
        WHEN rd."dependency_project_name" = 'gargoyle'                                THEN 'Gargoyle'
        WHEN rd."dependency_project_name" = 'gargoyle-yplan'                          THEN 'Gargoyle'
        WHEN rd."dependency_project_name" = 'unleash'                                 THEN 'unleash-client-ruby'
        WHEN rd."dependency_project_name" = 'ldclient-rb'                             THEN 'launchdarkly'
        WHEN rd."dependency_project_name" = 'rollout'                                 THEN 'rollout'
        WHEN rd."dependency_project_name" = 'feature_flipper'                         THEN 'FeatureFlipper'
        WHEN rd."dependency_project_name" = 'flip'                                    THEN 'Flip'
        WHEN rd."dependency_project_name" = 'setler'                                  THEN 'Setler'
        WHEN rd."dependency_project_name" = 'bandiera-client'                         THEN 'Bandiera'
        WHEN rd."dependency_project_name" = 'feature'                                 THEN 'Feature'
        WHEN rd."dependency_project_name" = 'flipper'                                 THEN 'Flipper'
        ELSE 'Unknown'
    END                                             AS library_name,
    /* map artifact -> library primary languages */
    CASE
        WHEN rd."dependency_project_name" IN ('Unleash.FeatureToggle.Client','unleash.client','LaunchDarkly.Client',
                                              'NFeature','FeatureToggle','FeatureSwitcher','Toggler')
             THEN 'C#,Visual Basic'
        WHEN rd."dependency_project_name" IN ('github.com/launchdarkly/go-client','github.com/xchapter7x/toggle',
                                              'github.com/vsco/dcdr','github.com/unleash/unleash-client-go')
             THEN 'Go'
        WHEN rd."dependency_project_name" IN ('unleash-client','ldclient-js','ember-feature-flags','feature-toggles',
                                              '@paralleldrive/react-feature-toggles','ldclient-node','flipit','fflip',
                                              'bandiera-client','@flopflip/react-redux','@flopflip/react-broadcast')
             THEN 'JavaScript,TypeScript'
        WHEN rd."dependency_project_name" IN ('com.launchdarkly:launchdarkly-android-client','cc.soham:toggle',
                                              'no.finn.unleash:unleash-client-java','com.launchdarkly:launchdarkly-client',
                                              'org.togglz:togglz-core','org.ff4j:ff4j-core','com.tacitknowledge.flip:core')
             THEN 'Kotlin,Java'
        WHEN rd."dependency_project_name" IN ('com.springernature:bandiera-client-scala_2.12',
                                              'com.springernature:bandiera-client-scala_2.11')
             THEN 'Scala'
        WHEN rd."dependency_project_name" IN ('launchdarkly/launchdarkly-php','dzunke/feature-flags-bundle',
                                              'opensoft/rollout','npg/bandiera-client-php')
             THEN 'PHP'
        WHEN rd."dependency_project_name" IN ('UnleashClient','ldclient-py','Flask-FeatureFlags','gutter',
                                              'feature_ramp','flagon','django-waffle','gargoyle','gargoyle-yplan')
             THEN 'Python'
        WHEN rd."dependency_project_name" IN ('unleash','ldclient-rb','rollout','feature_flipper','flip','setler',
                                              'bandiera-client','feature','flipper')
             THEN 'Ruby'
        ELSE NULL
    END                                             AS library_languages
FROM LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES rd
JOIN LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES           r
  ON r."id" = rd."repository_id"
WHERE rd."dependency_project_name" IN (
    /* .NET */
    'Unleash.FeatureToggle.Client','unleash.client','LaunchDarkly.Client','NFeature',
    'FeatureToggle','FeatureSwitcher','Toggler',
    /* Go */
    'github.com/launchdarkly/go-client','github.com/xchapter7x/toggle',
    'github.com/vsco/dcdr','github.com/unleash/unleash-client-go',
    /* NPM */
    'unleash-client','ldclient-js','ember-feature-flags','feature-toggles',
    '@paralleldrive/react-feature-toggles','ldclient-node','flipit','fflip',
    'bandiera-client','@flopflip/react-redux','@flopflip/react-broadcast',
    /* Maven / Java / Kotlin */
    'com.launchdarkly:launchdarkly-android-client','cc.soham:toggle',
    'no.finn.unleash:unleash-client-java','com.launchdarkly:launchdarkly-client',
    'org.togglz:togglz-core','org.ff4j:ff4j-core','com.tacitknowledge.flip:core',
    /* Scala */
    'com.springernature:bandiera-client-scala_2.12','com.springernature:bandiera-client-scala_2.11',
    /* PHP */
    'launchdarkly/launchdarkly-php','dzunke/feature-flags-bundle','opensoft/rollout','npg/bandiera-client-php',
    /* Python */
    'UnleashClient','ldclient-py','Flask-FeatureFlags','gutter','feature_ramp','flagon',
    'django-waffle','gargoyle','gargoyle-yplan',
    /* Ruby */
    'unleash','ldclient-rb','rollout','feature_flipper','flip','setler',
    'bandiera-client','feature','flipper'
)
ORDER BY r."updated_timestamp" DESC NULLS LAST;