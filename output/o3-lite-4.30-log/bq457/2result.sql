SELECT DISTINCT
  r.name_with_owner                     AS repo_full_name_with_owner,
  r.host_type                           AS hosting_platform_type,
  r.size * 1024                         AS size_bytes,          -- KiB → Bytes
  r.language                            AS primary_language,
  r.fork_source_name_with_owner         AS fork_source_name,
  r.updated_timestamp                   AS last_update_timestamp,
  p.name                                AS feature_toggle_artifact,
  CASE
      WHEN LOWER(p.name) LIKE '%unleash%'        THEN 'Unleash'
      WHEN LOWER(p.name) LIKE '%launchdarkly%'   THEN 'LaunchDarkly'
      WHEN LOWER(p.name) LIKE '%togglz%'         THEN 'Togglz'
      WHEN LOWER(p.name) LIKE '%ff4j%'           THEN 'FF4J'
      WHEN LOWER(p.name) LIKE '%flip%'           THEN 'Flip / Flipper'
      WHEN LOWER(p.name) LIKE '%rollout%'        THEN 'Rollout'
      WHEN LOWER(p.name) LIKE '%bandiera%'       THEN 'Bandiera'
      WHEN LOWER(p.name) LIKE '%waffle%'         THEN 'Waffle'
      WHEN LOWER(p.name) LIKE '%gargoyle%'       THEN 'Gargoyle'
      ELSE p.name
  END                                   AS feature_toggle_library_name,
  p.language                            AS feature_toggle_library_languages
FROM   `bigquery-public-data.libraries_io.repository_dependencies` AS rd
JOIN   `bigquery-public-data.libraries_io.repositories`            AS r
       ON r.id = rd.repository_id
JOIN   `bigquery-public-data.libraries_io.projects`                AS p
       ON p.id = rd.dependency_project_id
WHERE  LOWER(p.name) IN (
        'unleash.featuretoggle.client','unleash.client','launchdarkly.client',
        'nfeature','featuretoggle','featureswitcher','toggler',
        'github.com/launchdarkly/go-client','github.com/xchapter7x/toggle',
        'github.com/vsco/dcdr','github.com/unleash/unleash-client-go',
        'unleash-client','ldclient-js','ember-feature-flags','feature-toggles',
        '@paralleldrive/react-feature-toggles','ldclient-node','flipit','fflip',
        'bandiera-client','@flopflip/react-redux','@flopflip/react-broadcast',
        'com.launchdarkly:launchdarkly-android-client','cc.soham:toggle',
        'no.finn.unleash:unleash-client-java','com.launchdarkly:launchdarkly-client',
        'org.togglz:togglz-core','org.ff4j:ff4j-core','com.tacitknowledge.flip:core',
        'unleash','launchdarkly','launchdarkly/ios-client','ldclient-py',
        'unleashclient','feature_ramp','flask-featureflags','gutter','flagon',
        'django-waffle','gargoyle','gargoyle-yplan','launchdarkly/launchdarkly-php',
        'dzunke/feature-flags-bundle','opensoft/rollout','npg/bandiera-client-php',
        'rollout','feature_flipper','flip','setler','flipper'
      );