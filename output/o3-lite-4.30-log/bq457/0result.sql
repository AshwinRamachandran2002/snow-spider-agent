SELECT DISTINCT
       r.name_with_owner                                  AS repo_full_name_with_owner,
       r.host_type                                        AS hosting_platform_type,
       CAST(r.size * 1024 AS INT64)                       AS size_bytes,
       r.language                                         AS primary_language,
       r.fork_source_name_with_owner                      AS fork_source_name,
       r.updated_timestamp                                AS last_update_timestamp,
       rd.dependency_project_name                         AS feature_toggle_artifact,
       p.name                                             AS feature_toggle_library_name,
       p.language                                         AS feature_toggle_library_languages
FROM   `bigquery-public-data.libraries_io.repository_dependencies` rd
JOIN   `bigquery-public-data.libraries_io.repositories`           r
       ON r.id = rd.repository_id
JOIN   `bigquery-public-data.libraries_io.projects`               p
       ON p.id = rd.dependency_project_id
WHERE  LOWER(rd.dependency_project_name) IN (
       -- JavaScript / TypeScript
       'unleash-client', '@paralleldrive/react-feature-toggles', 'ldclient-js',
       'ldclient-node', 'ember-feature-flags', 'feature-toggles',
       'flipit', 'fflip', 'bandiera-client', '@flopflip/react-redux',
       '@flopflip/react-broadcast',
       -- Java / Kotlin / Scala
       'no.finn.unleash:unleash-client-java', 'org.togglz:togglz-core',
       'org.ff4j:ff4j-core', 'com.launchdarkly:launchdarkly-client',
       'com.launchdarkly:launchdarkly-android-client', 'cc.soham:toggle',
       'com.tacitknowledge.flip:core', 'com.springernature:bandiera-client-scala_2.12',
       'com.springernature:bandiera-client-scala_2.11',
       -- Go
       'github.com/launchdarkly/go-client', 'github.com/xchapter7x/toggle',
       'github.com/vsco/dcdr', 'github.com/unleash/unleash-client-go',
       -- .NET (NuGet)
       'unleash.featuretoggle.client', 'unleash.client', 'launchdarkly.client',
       'nfeature', 'featuretoggle', 'featureswitcher', 'toggler',
       -- Python (PyPI)
       'unleashclient', 'ldclient-py', 'flask-featureflags', 'gutter',
       'feature_ramp', 'flagon', 'django-waffle', 'gargoyle', 'gargoyle-yplan',
       -- Ruby (Rubygems)
       'unleash', 'ldclient-rb', 'rollout', 'feature_flipper',
       'flip', 'setler', 'bandiera-client', 'feature', 'flipper',
       -- PHP (Packagist)
       'launchdarkly/launchdarkly-php', 'dzunke/feature-flags-bundle',
       'opensoft/rollout', 'npg/bandiera-client-php',
       -- iOS (CocoaPods / Carthage)
       'launchdarkly', 'launchdarkly/ios-client'
)
ORDER BY repo_full_name_with_owner;