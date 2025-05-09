/* -----------------------------------------------------------
   Feature-toggle usage across open-source repositories
----------------------------------------------------------- */
WITH feature_toggle_libs AS (
  SELECT *
  FROM UNNEST(
    ARRAY<STRUCT<
        artifact_name STRING,
        library_name  STRING,
        languages     STRING
    >>[
      -- JavaScript / TypeScript
      ('ldclient-js'                         ,'launchdarkly'            ,'JavaScript,TypeScript'),
      ('ldclient-node'                       ,'launchdarkly'            ,'JavaScript,TypeScript'),
      ('unleash-client'                      ,'unleash-client-node'     ,'JavaScript,TypeScript'),
      ('ember-feature-flags'                 ,'ember-feature-flags'     ,'JavaScript,TypeScript'),
      ('feature-toggles'                     ,'feature-toggles'         ,'JavaScript,TypeScript'),
      ('@paralleldrive/react-feature-toggles','react-feature-toggles'   ,'JavaScript,TypeScript'),
      ('flipit'                              ,'flipit'                  ,'JavaScript,TypeScript'),
      ('fflip'                               ,'fflip'                   ,'JavaScript,TypeScript'),
      ('bandiera-client'                     ,'Bandiera'                ,'JavaScript,TypeScript'),
      ('@flopflip/react-redux'               ,'flopflip'                ,'JavaScript,TypeScript'),
      ('@flopflip/react-broadcast'           ,'flopflip'                ,'JavaScript,TypeScript'),

      -- Go
      ('github.com/launchdarkly/go-client'        ,'launchdarkly'       ,'Go'),
      ('github.com/xchapter7x/toggle'             ,'toggle'             ,'Go'),
      ('github.com/vsco/dcdr'                     ,'dcdr'               ,'Go'),
      ('github.com/unleash/unleash-client-go'     ,'unleash-client-go'  ,'Go'),

      -- Java / Kotlin / Scala
      ('com.launchdarkly:launchdarkly-android-client','launchdarkly'   ,'Java,Kotlin'),
      ('cc.soham:toggle'                          ,'toggle'            ,'Java,Kotlin'),
      ('no.finn.unleash:unleash-client-java'      ,'unleash-client-java','Java,Kotlin'),
      ('com.launchdarkly:launchdarkly-client'     ,'launchdarkly'      ,'Java,Kotlin'),
      ('org.togglz:togglz-core'                   ,'Togglz'            ,'Java,Kotlin'),
      ('org.ff4j:ff4j-core'                       ,'FF4J'              ,'Java,Kotlin'),
      ('com.tacitknowledge.flip:core'             ,'Flip'              ,'Java,Kotlin'),
      ('com.springernature:bandiera-client-scala_2.12','Bandiera'      ,'Scala'),
      ('com.springernature:bandiera-client-scala_2.11','Bandiera'      ,'Scala'),

      -- .NET
      ('Unleash.FeatureToggle.Client' ,'unleash-client-dotnet' ,'.NET'),
      ('unleash.client'               ,'unleash-client'        ,'.NET'),
      ('LaunchDarkly.Client'          ,'launchdarkly'          ,'.NET'),
      ('NFeature'                     ,'NFeature'              ,'.NET'),
      ('FeatureToggle'                ,'FeatureToggle'         ,'.NET'),
      ('FeatureSwitcher'              ,'FeatureSwitcher'       ,'.NET'),
      ('Toggler'                      ,'Toggler'               ,'.NET'),

      -- iOS (CocoaPods / Carthage)
      ('LaunchDarkly'                 ,'launchdarkly'          ,'Objective-C,Swift'),
      ('launchdarkly/ios-client'      ,'launchdarkly'          ,'Objective-C,Swift'),

      -- PHP
      ('launchdarkly/launchdarkly-php','launchdarkly'          ,'PHP'),
      ('dzunke/feature-flags-bundle'  ,'Symfony FeatureFlagsBundle','PHP'),
      ('opensoft/rollout'             ,'rollout'               ,'PHP'),
      ('npg/bandiera-client-php'      ,'Bandiera'              ,'PHP'),

      -- Python
      ('UnleashClient'                ,'unleash-client-python' ,'Python'),
      ('ldclient-py'                  ,'launchdarkly'          ,'Python'),
      ('Flask-FeatureFlags'           ,'Flask FeatureFlags'    ,'Python'),
      ('gutter'                       ,'Gutter'                ,'Python'),
      ('feature_ramp'                 ,'Feature Ramp'          ,'Python'),
      ('flagon'                       ,'flagon'                ,'Python'),
      ('django-waffle'                ,'Waffle'                ,'Python'),
      ('gargoyle'                     ,'Gargoyle'              ,'Python'),
      ('gargoyle-yplan'               ,'Gargoyle'              ,'Python'),

      -- Ruby
      ('unleash'                      ,'unleash-client-ruby'   ,'Ruby'),
      ('ldclient-rb'                  ,'launchdarkly'          ,'Ruby'),
      ('rollout'                      ,'rollout'               ,'Ruby'),
      ('feature_flipper'              ,'FeatureFlipper'        ,'Ruby'),
      ('flip'                         ,'Flip'                  ,'Ruby'),
      ('setler'                       ,'Setler'                ,'Ruby'),
      ('bandiera-client'              ,'Bandiera'              ,'Ruby'),
      ('feature'                      ,'Feature'               ,'Ruby'),
      ('flipper'                      ,'Flipper'               ,'Ruby')
    ]
  )
)

SELECT DISTINCT
       rd.repository_name_with_owner                    AS repository_full_name,
       COALESCE(r.host_type, rd.host_type)              AS hosting_platform,
       r.size * 1024                                    AS repo_size_bytes,
       r.language                                       AS primary_language,
       r.fork_source_name_with_owner                    AS fork_source_name,
       r.updated_timestamp                              AS last_repo_update_utc,
       rd.dependency_project_name                       AS artifact_name,
       ft.library_name,
       ft.languages                                     AS library_languages
FROM   `bigquery-public-data.libraries_io.repository_dependencies` rd
JOIN   feature_toggle_libs   AS ft
       ON LOWER(rd.dependency_project_name) = LOWER(ft.artifact_name)
LEFT JOIN `bigquery-public-data.libraries_io.repositories` r
       ON r.name_with_owner = rd.repository_name_with_owner;