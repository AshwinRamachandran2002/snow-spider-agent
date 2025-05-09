-- Repositories that declare one of the known “feature toggle” libraries
-- (see feature_libs CTE) in one of their dependency manifests

WITH feature_libs AS (
  SELECT *
  FROM UNNEST ([
    STRUCT('Unleash.FeatureToggle.Client'             AS artifact_name,'unleash-client-dotnet'     AS library_name,'C#, Visual Basic'          AS languages),
    ('unleash.client'                                 ,'unleash-client'            ,'C#, Visual Basic'),
    ('LaunchDarkly.Client'                            ,'launchdarkly'              ,'C#, Visual Basic'),
    ('NFeature'                                       ,'NFeature'                  ,'C#, Visual Basic'),
    ('FeatureToggle'                                  ,'FeatureToggle'             ,'C#, Visual Basic'),
    ('FeatureSwitcher'                                ,'FeatureSwitcher'           ,'C#, Visual Basic'),
    ('Toggler'                                        ,'Toggler'                   ,'C#, Visual Basic'),
    
    ('github.com/launchdarkly/go-client'              ,'launchdarkly'              ,'Go'),
    ('github.com/xchapter7x/toggle'                   ,'Toggle'                    ,'Go'),
    ('github.com/vsco/dcdr'                           ,'dcdr'                      ,'Go'),
    ('github.com/unleash/unleash-client-go'           ,'unleash-client-go'         ,'Go'),
    
    ('unleash-client'                                 ,'unleash-client-node'       ,'JavaScript, TypeScript'),
    ('ldclient-js'                                    ,'launchdarkly'              ,'JavaScript, TypeScript'),
    ('ember-feature-flags'                            ,'ember-feature-flags'       ,'JavaScript, TypeScript'),
    ('feature-toggles'                                ,'feature-toggles'           ,'JavaScript, TypeScript'),
    ('@paralleldrive/react-feature-toggles'           ,'React Feature Toggles'     ,'JavaScript, TypeScript'),
    ('ldclient-node'                                  ,'launchdarkly'              ,'JavaScript, TypeScript'),
    ('flipit'                                         ,'flipit'                    ,'JavaScript, TypeScript'),
    ('fflip'                                          ,'fflip'                     ,'JavaScript, TypeScript'),
    ('bandiera-client'                                ,'Bandiera'                  ,'JavaScript, TypeScript'),
    ('@flopflip/react-redux'                          ,'flopflip'                  ,'JavaScript, TypeScript'),
    ('@flopflip/react-broadcast'                      ,'flopflip'                  ,'JavaScript, TypeScript'),
    
    ('com.launchdarkly:launchdarkly-android-client'   ,'launchdarkly'              ,'Kotlin, Java'),
    ('cc.soham:toggle'                                ,'toggle'                    ,'Kotlin, Java'),
    ('no.finn.unleash:unleash-client-java'            ,'unleash-client-java'       ,'Kotlin, Java'),
    ('com.launchdarkly:launchdarkly-client'           ,'launchdarkly'              ,'Kotlin, Java'),
    ('org.togglz:togglz-core'                         ,'Togglz'                    ,'Kotlin, Java'),
    ('org.ff4j:ff4j-core'                             ,'FF4J'                      ,'Kotlin, Java'),
    ('com.tacitknowledge.flip:core'                   ,'Flip'                      ,'Kotlin, Java'),
    
    ('LaunchDarkly'                                   ,'launchdarkly'              ,'Objective‑C, Swift'),
    ('launchdarkly/ios-client'                        ,'launchdarkly'              ,'Objective‑C, Swift'),
    
    ('launchdarkly/launchdarkly-php'                  ,'launchdarkly'              ,'PHP'),
    ('dzunke/feature-flags-bundle'                    ,'Symfony FeatureFlagsBundle','PHP'),
    ('opensoft/rollout'                               ,'rollout'                   ,'PHP'),
    ('npg/bandiera-client-php'                        ,'Bandiera'                  ,'PHP'),
    
    ('UnleashClient'                                  ,'unleash-client-python'     ,'Python'),
    ('ldclient-py'                                    ,'launchdarkly'              ,'Python'),
    ('Flask-FeatureFlags'                             ,'Flask FeatureFlags'        ,'Python'),
    ('gutter'                                         ,'Gutter'                    ,'Python'),
    ('feature_ramp'                                   ,'Feature Ramp'              ,'Python'),
    ('flagon'                                         ,'flagon'                    ,'Python'),
    ('django-waffle'                                  ,'Waffle'                    ,'Python'),
    ('gargoyle'                                       ,'Gargoyle'                  ,'Python'),
    ('gargoyle-yplan'                                 ,'Gargoyle'                  ,'Python'),
    
    ('unleash'                                        ,'unleash-client-ruby'       ,'Ruby'),
    ('ldclient-rb'                                    ,'launchdarkly'              ,'Ruby'),
    ('rollout'                                        ,'rollout'                   ,'Ruby'),
    ('feature_flipper'                                ,'FeatureFlipper'            ,'Ruby'),
    ('flip'                                           ,'Flip'                      ,'Ruby'),
    ('setler'                                         ,'Setler'                    ,'Ruby'),
    ('bandiera-client'                                ,'Bandiera'                  ,'Ruby'),
    ('feature'                                        ,'Feature'                   ,'Ruby'),
    ('flipper'                                        ,'Flipper'                   ,'Ruby'),
    
    ('com.springernature:bandiera-client-scala_2.12'  ,'Bandiera'                  ,'Scala'),
    ('com.springernature:bandiera-client-scala_2.11'  ,'Bandiera'                  ,'Scala')
  ]) AS t
)

SELECT DISTINCT
  repo.name_with_owner                      AS repository_full_name,
  repo.host_type                            AS hosting_platform,
  CAST(repo.size * 1024 AS INT64)           AS size_bytes,
  repo.language                             AS primary_language,
  repo.fork_source_name_with_owner          AS fork_source,
  repo.updated_timestamp                    AS last_updated_timestamp,
  fl.artifact_name,
  fl.library_name,
  fl.languages                              AS library_languages
FROM `bigquery-public-data.libraries_io.repository_dependencies`  AS rd
JOIN `bigquery-public-data.libraries_io.repositories`             AS repo
      ON repo.id = rd.repository_id
JOIN feature_libs                                                 AS fl
      ON LOWER(TRIM(rd.dependency_project_name)) = LOWER(fl.artifact_name)
ORDER BY repository_full_name, fl.artifact_name;