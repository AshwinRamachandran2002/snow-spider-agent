WITH toggle_libs AS (
    SELECT column1 AS artifact_name,
           column2 AS library_name,
           column3 AS library_languages,
           column4 AS library_platform
    FROM VALUES
        /* .NET / NuGet */
        ('Unleash.FeatureToggle.Client'             ,'unleash-client-dotnet'   ,'C#,Visual Basic','NuGet'),
        ('unleash.client'                           ,'unleash-client'          ,'C#,Visual Basic','NuGet'),
        ('LaunchDarkly.Client'                      ,'launchdarkly'            ,'C#,Visual Basic','NuGet'),
        ('NFeature'                                 ,'NFeature'                ,'C#,Visual Basic','NuGet'),
        ('FeatureToggle'                            ,'FeatureToggle'           ,'C#,Visual Basic','NuGet'),
        ('FeatureSwitcher'                          ,'FeatureSwitcher'         ,'C#,Visual Basic','NuGet'),
        ('Toggler'                                  ,'Toggler'                 ,'C#,Visual Basic','NuGet'),

        /* Go */
        ('github.com/launchdarkly/go-client'        ,'launchdarkly'            ,'Go'             ,'Go'),
        ('github.com/xchapter7x/toggle'             ,'Toggle'                  ,'Go'             ,'Go'),
        ('github.com/vsco/dcdr'                     ,'dcdr'                    ,'Go'             ,'Go'),
        ('github.com/unleash/unleash-client-go'     ,'unleash-client-go'       ,'Go'             ,'Go'),

        /* JavaScript / NPM */
        ('unleash-client'                           ,'unleash-client-node'     ,'JavaScript,TypeScript','NPM'),
        ('ldclient-js'                              ,'launchdarkly'            ,'JavaScript,TypeScript','NPM'),
        ('ember-feature-flags'                      ,'ember-feature-flags'     ,'JavaScript,TypeScript','NPM'),
        ('feature-toggles'                          ,'feature-toggles'         ,'JavaScript,TypeScript','NPM'),
        ('@paralleldrive/react-feature-toggles'     ,'React Feature Toggles'   ,'JavaScript,TypeScript','NPM'),
        ('ldclient-node'                            ,'launchdarkly'            ,'JavaScript,TypeScript','NPM'),
        ('flipit'                                   ,'flipit'                  ,'JavaScript,TypeScript','NPM'),
        ('fflip'                                    ,'fflip'                   ,'JavaScript,TypeScript','NPM'),
        ('bandiera-client'                          ,'Bandiera'                ,'JavaScript,TypeScript','NPM'),
        ('@flopflip/react-redux'                    ,'flopflip'                ,'JavaScript,TypeScript','NPM'),
        ('@flopflip/react-broadcast'                ,'flopflip'                ,'JavaScript,TypeScript','NPM'),

        /* Maven / JVM */
        ('com.launchdarkly:launchdarkly-android-client','launchdarkly'        ,'Kotlin,Java'    ,'Maven'),
        ('cc.soham:toggle'                          ,'toggle'                  ,'Kotlin,Java'    ,'Maven'),
        ('no.finn.unleash:unleash-client-java'      ,'unleash-client-java'     ,'Kotlin,Java'    ,'Maven'),
        ('com.launchdarkly:launchdarkly-client'     ,'launchdarkly'            ,'Kotlin,Java'    ,'Maven'),
        ('org.togglz:togglz-core'                   ,'Togglz'                  ,'Kotlin,Java'    ,'Maven'),
        ('org.ff4j:ff4j-core'                       ,'FF4J'                    ,'Kotlin,Java'    ,'Maven'),
        ('com.tacitknowledge.flip:core'             ,'Flip'                    ,'Kotlin,Java'    ,'Maven'),
        ('com.springernature:bandiera-client-scala_2.12','Bandiera'           ,'Scala'          ,'Maven'),
        ('com.springernature:bandiera-client-scala_2.11','Bandiera'           ,'Scala'          ,'Maven'),

        /* iOS */
        ('LaunchDarkly'                             ,'launchdarkly'            ,'Objective-C,Swift','CocoaPods'),
        ('launchdarkly/ios-client'                  ,'launchdarkly'            ,'Objective-C,Swift','Carthage'),

        /* PHP / Packagist */
        ('launchdarkly/launchdarkly-php'            ,'launchdarkly'            ,'PHP'            ,'Packagist'),
        ('dzunke/feature-flags-bundle'              ,'Symfony FeatureFlagsBundle','PHP'         ,'Packagist'),
        ('opensoft/rollout'                         ,'rollout'                 ,'PHP'            ,'Packagist'),
        ('npg/bandiera-client-php'                  ,'Bandiera'                ,'PHP'            ,'Packagist'),

        /* Python / PyPI */
        ('UnleashClient'                            ,'unleash-client-python'   ,'Python'         ,'Pypi'),
        ('ldclient-py'                              ,'launchdarkly'            ,'Python'         ,'Pypi'),
        ('Flask-FeatureFlags'                       ,'Flask FeatureFlags'      ,'Python'         ,'Pypi'),
        ('gutter'                                   ,'Gutter'                  ,'Python'         ,'Pypi'),
        ('feature_ramp'                             ,'Feature Ramp'            ,'Python'         ,'Pypi'),
        ('flagon'                                   ,'flagon'                  ,'Python'         ,'Pypi'),
        ('django-waffle'                            ,'Waffle'                  ,'Python'         ,'Pypi'),
        ('gargoyle'                                 ,'Gargoyle'                ,'Python'         ,'Pypi'),
        ('gargoyle-yplan'                           ,'Gargoyle'                ,'Python'         ,'Pypi'),

        /* Ruby / Rubygems */
        ('unleash'                                  ,'unleash-client-ruby'     ,'Ruby'           ,'Rubygems'),
        ('ldclient-rb'                              ,'launchdarkly'            ,'Ruby'           ,'Rubygems'),
        ('rollout'                                  ,'rollout'                 ,'Ruby'           ,'Rubygems'),
        ('feature_flipper'                          ,'FeatureFlipper'          ,'Ruby'           ,'Rubygems'),
        ('flip'                                     ,'Flip'                    ,'Ruby'           ,'Rubygems'),
        ('setler'                                   ,'Setler'                  ,'Ruby'           ,'Rubygems'),
        ('bandiera-client'                          ,'Bandiera'                ,'Ruby'           ,'Rubygems'),
        ('feature'                                  ,'Feature'                 ,'Ruby'           ,'Rubygems'),
        ('flipper'                                  ,'Flipper'                 ,'Ruby'           ,'Rubygems')
)

SELECT DISTINCT
       r."name_with_owner"             AS "repository_full_name",
       r."host_type"                   AS "hosting_platform_type",
       r."size"                        AS "size_bytes",
       r."language"                    AS "primary_language",
       r."fork_source_name_with_owner" AS "fork_source_name",
       r."updated_timestamp"           AS "repository_last_update_ts",
       tl.artifact_name                AS "feature_toggle_artifact",
       tl.library_name                 AS "feature_toggle_library",
       tl.library_languages            AS "library_languages"
FROM LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES rd
JOIN LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES         r
     ON rd."repository_id" = r."id"
JOIN toggle_libs                                    tl
     ON LOWER(TRIM(rd."dependency_project_name")) = LOWER(tl.artifact_name)
ORDER BY r."updated_timestamp" DESC NULLS LAST;