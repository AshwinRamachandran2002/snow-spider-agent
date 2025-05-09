/* Repositories that depend on one of the known Feature-Toggle libraries */
SELECT   R."name_with_owner"                         AS "repository_full_name",
         R."host_type"                               AS "hosting_platform_type",
         R."size"                                    AS "size_bytes",
         R."language"                                AS "primary_programming_language",
         R."fork_source_name_with_owner"             AS "fork_source_name_with_owner",
         R."updated_timestamp"                       AS "last_updated_timestamp",
         RD."dependency_project_name"                AS "artifact_name",
         /* map artifact → canonical library name */
         CASE RD."dependency_project_name"
              WHEN 'Unleash.FeatureToggle.Client'                       THEN 'unleash-client-dotnet'
              WHEN 'unleash.client'                                     THEN 'unleash-client'
              WHEN 'LaunchDarkly.Client'                                THEN 'launchdarkly'
              WHEN 'NFeature'                                           THEN 'NFeature'
              WHEN 'FeatureToggle'                                      THEN 'FeatureToggle'
              WHEN 'FeatureSwitcher'                                    THEN 'FeatureSwitcher'
              WHEN 'Toggler'                                            THEN 'Toggler'
              WHEN 'github.com/launchdarkly/go-client'                  THEN 'launchdarkly'
              WHEN 'github.com/xchapter7x/toggle'                       THEN 'Toggle'
              WHEN 'github.com/vsco/dcdr'                               THEN 'dcdr'
              WHEN 'github.com/unleash/unleash-client-go'               THEN 'unleash-client-go'
              WHEN 'unleash-client'                                     THEN 'unleash-client-node'
              WHEN 'ldclient-js'                                        THEN 'launchdarkly'
              WHEN 'ember-feature-flags'                                THEN 'ember-feature-flags'
              WHEN 'feature-toggles'                                    THEN 'feature-toggles'
              WHEN '@paralleldrive/react-feature-toggles'               THEN 'React Feature Toggles'
              WHEN 'ldclient-node'                                      THEN 'launchdarkly'
              WHEN 'flipit'                                             THEN 'flipit'
              WHEN 'fflip'                                              THEN 'fflip'
              WHEN 'bandiera-client'                                    THEN 'Bandiera'
              WHEN '@flopflip/react-redux'                              THEN 'flopflip'
              WHEN '@flopflip/react-broadcast'                          THEN 'flopflip'
              WHEN 'com.launchdarkly:launchdarkly-android-client'       THEN 'launchdarkly'
              WHEN 'cc.soham:toggle'                                    THEN 'toggle'
              WHEN 'no.finn.unleash:unleash-client-java'               THEN 'unleash-client-java'
              WHEN 'com.launchdarkly:launchdarkly-client'               THEN 'launchdarkly'
              WHEN 'org.togglz:togglz-core'                             THEN 'Togglz'
              WHEN 'org.ff4j:ff4j-core'                                 THEN 'FF4J'
              WHEN 'com.tacitknowledge.flip:core'                       THEN 'Flip'
              WHEN 'com.springernature:bandiera-client-scala_2.12'      THEN 'Bandiera'
              WHEN 'com.springernature:bandiera-client-scala_2.11'      THEN 'Bandiera'
              WHEN 'LaunchDarkly'                                       THEN 'launchdarkly'
              WHEN 'launchdarkly/ios-client'                            THEN 'launchdarkly'
              WHEN 'launchdarkly/launchdarkly-php'                      THEN 'launchdarkly'
              WHEN 'dzunke/feature-flags-bundle'                        THEN 'Symfony FeatureFlagsBundle'
              WHEN 'opensoft/rollout'                                   THEN 'rollout'
              WHEN 'npg/bandiera-client-php'                            THEN 'Bandiera'
              WHEN 'UnleashClient'                                      THEN 'unleash-client-python'
              WHEN 'ldclient-py'                                        THEN 'launchdarkly'
              WHEN 'Flask-FeatureFlags'                                 THEN 'Flask FeatureFlags'
              WHEN 'gutter'                                             THEN 'Gutter'
              WHEN 'feature_ramp'                                       THEN 'Feature Ramp'
              WHEN 'flagon'                                             THEN 'flagon'
              WHEN 'django-waffle'                                      THEN 'Waffle'
              WHEN 'gargoyle'                                           THEN 'Gargoyle'
              WHEN 'gargoyle-yplan'                                     THEN 'Gargoyle'
              WHEN 'unleash'                                            THEN 'unleash-client-ruby'
              WHEN 'ldclient-rb'                                        THEN 'launchdarkly'
              WHEN 'rollout'                                            THEN 'rollout'
              WHEN 'feature_flipper'                                    THEN 'FeatureFlipper'
              WHEN 'flip'                                               THEN 'Flip'
              WHEN 'setler'                                             THEN 'Setler'
              WHEN 'feature'                                            THEN 'Feature'
              WHEN 'flipper'                                            THEN 'Flipper'
         END                                            AS "library_name",
         /* map artifact → library languages */
         CASE RD."dependency_project_name"
              WHEN 'Unleash.FeatureToggle.Client'                        THEN 'C#, Visual Basic'
              WHEN 'unleash.client'                                      THEN 'C#, Visual Basic'
              WHEN 'LaunchDarkly.Client'                                 THEN 'C#, Visual Basic'
              WHEN 'NFeature'                                           THEN 'C#, Visual Basic'
              WHEN 'FeatureToggle'                                      THEN 'C#, Visual Basic'
              WHEN 'FeatureSwitcher'                                    THEN 'C#, Visual Basic'
              WHEN 'Toggler'                                            THEN 'C#, Visual Basic'
              WHEN 'github.com/launchdarkly/go-client'                  THEN 'Go'
              WHEN 'github.com/xchapter7x/toggle'                       THEN 'Go'
              WHEN 'github.com/vsco/dcdr'                               THEN 'Go'
              WHEN 'github.com/unleash/unleash-client-go'               THEN 'Go'
              WHEN 'unleash-client'                                     THEN 'JavaScript, TypeScript'
              WHEN 'ldclient-js'                                        THEN 'JavaScript, TypeScript'
              WHEN 'ember-feature-flags'                                THEN 'JavaScript, TypeScript'
              WHEN 'feature-toggles'                                    THEN 'JavaScript, TypeScript'
              WHEN '@paralleldrive/react-feature-toggles'               THEN 'JavaScript, TypeScript'
              WHEN 'ldclient-node'                                      THEN 'JavaScript, TypeScript'
              WHEN 'flipit'                                             THEN 'JavaScript, TypeScript'
              WHEN 'fflip'                                              THEN 'JavaScript, TypeScript'
              WHEN 'bandiera-client'                                    THEN 'JavaScript, TypeScript'
              WHEN '@flopflip/react-redux'                              THEN 'JavaScript, TypeScript'
              WHEN '@flopflip/react-broadcast'                          THEN 'JavaScript, TypeScript'
              WHEN 'com.launchdarkly:launchdarkly-android-client'       THEN 'Kotlin, Java'
              WHEN 'cc.soham:toggle'                                    THEN 'Kotlin, Java'
              WHEN 'no.finn.unleash:unleash-client-java'               THEN 'Kotlin, Java'
              WHEN 'com.launchdarkly:launchdarkly-client'               THEN 'Kotlin, Java'
              WHEN 'org.togglz:togglz-core'                             THEN 'Kotlin, Java'
              WHEN 'org.ff4j:ff4j-core'                                 THEN 'Kotlin, Java'
              WHEN 'com.tacitknowledge.flip:core'                       THEN 'Kotlin, Java'
              WHEN 'com.springernature:bandiera-client-scala_2.12'      THEN 'Scala'
              WHEN 'com.springernature:bandiera-client-scala_2.11'      THEN 'Scala'
              WHEN 'LaunchDarkly'                                       THEN 'Objective-C, Swift'
              WHEN 'launchdarkly/ios-client'                            THEN 'Objective-C, Swift'
              WHEN 'launchdarkly/launchdarkly-php'                      THEN 'PHP'
              WHEN 'dzunke/feature-flags-bundle'                        THEN 'PHP'
              WHEN 'opensoft/rollout'                                   THEN 'PHP'
              WHEN 'npg/bandiera-client-php'                            THEN 'PHP'
              WHEN 'UnleashClient'                                      THEN 'Python'
              WHEN 'ldclient-py'                                        THEN 'Python'
              WHEN 'Flask-FeatureFlags'                                 THEN 'Python'
              WHEN 'gutter'                                             THEN 'Python'
              WHEN 'feature_ramp'                                       THEN 'Python'
              WHEN 'flagon'                                             THEN 'Python'
              WHEN 'django-waffle'                                      THEN 'Python'
              WHEN 'gargoyle'                                           THEN 'Python'
              WHEN 'gargoyle-yplan'                                     THEN 'Python'
              WHEN 'unleash'                                            THEN 'Ruby'
              WHEN 'ldclient-rb'                                        THEN 'Ruby'
              WHEN 'rollout'                                            THEN 'Ruby'
              WHEN 'feature_flipper'                                    THEN 'Ruby'
              WHEN 'flip'                                               THEN 'Ruby'
              WHEN 'setler'                                             THEN 'Ruby'
              WHEN 'bandiera-client'                                    THEN 'Ruby'
              WHEN 'feature'                                            THEN 'Ruby'
              WHEN 'flipper'                                            THEN 'Ruby'
         END                                            AS "library_programming_languages"
FROM     LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES            R
JOIN     LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES RD
       ON R."id" = RD."repository_id"
WHERE    RD."dependency_project_name" IN (
           'Unleash.FeatureToggle.Client','unleash.client','LaunchDarkly.Client','NFeature',
           'FeatureToggle','FeatureSwitcher','Toggler',
           'github.com/launchdarkly/go-client','github.com/xchapter7x/toggle',
           'github.com/vsco/dcdr','github.com/unleash/unleash-client-go',
           'unleash-client','ldclient-js','ember-feature-flags','feature-toggles',
           '@paralleldrive/react-feature-toggles','ldclient-node','flipit','fflip',
           'bandiera-client','@flopflip/react-redux','@flopflip/react-broadcast',
           'com.launchdarkly:launchdarkly-android-client','cc.soham:toggle',
           'no.finn.unleash:unleash-client-java','com.launchdarkly:launchdarkly-client',
           'org.togglz:togglz-core','org.ff4j:ff4j-core','com.tacitknowledge.flip:core',
           'com.springernature:bandiera-client-scala_2.12','com.springernature:bandiera-client-scala_2.11',
           'LaunchDarkly','launchdarkly/ios-client','launchdarkly/launchdarkly-php',
           'dzunke/feature-flags-bundle','opensoft/rollout','npg/bandiera-client-php',
           'UnleashClient','ldclient-py','Flask-FeatureFlags','gutter','feature_ramp',
           'flagon','django-waffle','gargoyle','gargoyle-yplan','unleash','ldclient-rb',
           'rollout','feature_flipper','flip','setler','bandiera-client','feature','flipper'
         )
ORDER BY R."updated_timestamp" DESC NULLS LAST;