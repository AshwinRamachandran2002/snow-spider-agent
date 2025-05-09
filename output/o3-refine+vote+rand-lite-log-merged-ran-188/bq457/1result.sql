/*  Repositories that declare one of the well-known feature–toggle libraries
    (see explicit artefact list below) in one of their manifest / lock files.  */

WITH feature_toggle_libs AS (
  -- canonical (lower–cased) artefact names that identify the wanted libraries
  SELECT *
  FROM UNNEST([
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

      'launchdarkly','launchdarkly/ios-client','launchdarkly/launchdarkly-php',
      'dzunke/feature-flags-bundle','opensoft/rollout','npg/bandiera-client-php',

      'unleashclient','ldclient-py','flask-featureflags','gutter',
      'feature_ramp','flagon','django-waffle','gargoyle','gargoyle-yplan',

      'unleash','ldclient-rb','rollout','feature_flipper','flip','setler',
      'bandiera-client','feature','flipper',

      'com.springernature:bandiera-client-scala_2.12',
      'com.springernature:bandiera-client-scala_2.11'
  ]) AS artefact_name_lower
)

SELECT DISTINCT
  COALESCE(r.name_with_owner, d.repository_name_with_owner)  AS repository_full_name,
  d.host_type,
  r.size * 1024                                              AS size_bytes,           -- KB → bytes
  r.language                                                 AS primary_language,
  r.fork_source_name_with_owner,
  r.updated_timestamp,
  p.name                                                     AS artefact_name,
  CASE
      WHEN LOWER(p.name) LIKE '%unleash%'        THEN 'Unleash'
      WHEN LOWER(p.name) LIKE '%launchdarkly%'   THEN 'LaunchDarkly'
      WHEN LOWER(p.name) LIKE '%togglz%'         THEN 'Togglz'
      WHEN LOWER(p.name) LIKE '%flipper%'        THEN 'Flipper'
      WHEN LOWER(p.name) LIKE '%ff4j%'           THEN 'FF4J'
      WHEN LOWER(p.name) LIKE '%bandiera%'       THEN 'Bandiera'
      WHEN LOWER(p.name) LIKE '%rollout%'        THEN 'Rollout'
      WHEN LOWER(p.name) LIKE '%toggle%'         THEN 'Toggle'
      WHEN LOWER(p.name) LIKE '%gargoyle%'       THEN 'Gargoyle'
      WHEN LOWER(p.name) LIKE '%waffle%'         THEN 'Waffle'
      ELSE p.name
  END                                                      AS library_name,
  p.language                                               AS library_languages
FROM   `bigquery-public-data.libraries_io.repository_dependencies` AS d
JOIN   `bigquery-public-data.libraries_io.projects`                AS p
       ON d.dependency_project_id = p.id
JOIN   feature_toggle_libs ft
       ON LOWER(p.name) = ft.artefact_name_lower            -- keep only wanted artefacts
LEFT  JOIN `bigquery-public-data.libraries_io.repositories`        AS r
       ON d.repository_id = r.id
ORDER BY repository_full_name, artefact_name;