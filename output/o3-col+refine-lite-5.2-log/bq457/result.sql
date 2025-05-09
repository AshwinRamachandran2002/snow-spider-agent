/* -------------------------------------------------------------
   Repositories that declare (in any manifest / lock‑file) one of
   the well‑known “Feature‑Toggle” libraries.
   -----------------------------------------------------------------
   Returned columns
     • repository_full_name          – owner/repo
     • host_type                     – GitHub / GitLab / Bitbucket
     • size_bytes                    – repository size (KB → B)
     • repository_language           – main language of the repo
     • fork_source_name_with_owner   – original repo if this is a fork
     • repository_updated_timestamp  – last time Libraries.io saw a change
     • artifact_name                 – exact string used in the manifest
     • library_name                  – canonical name of the feature‑toggle
     • library_platform              – Package–manager (NPM, Maven, …)
     • library_languages             – languages the library itself is written in
   ----------------------------------------------------------------- */

WITH feature_toggle_libs AS (
  SELECT LOWER(lib) AS lib_name
  FROM UNNEST([
    -- ❶  .NET / NuGet
    'unleash.featuretoggle.client','unleash.client','launchdarkly.client',
    'nfeature','featuretoggle','featureswitcher','toggler',

    -- ❷  JavaScript / TypeScript – NPM
    'unleash-client','ldclient-js','ldclient-node','ember-feature-flags',
    'feature-toggles','@paralleldrive/react-feature-toggles',
    'flipit','fflip','bandiera-client',
    '@flopflip/react-redux','@flopflip/react-broadcast',

    -- ❸  Java / Kotlin / Scala – Maven‑Central
    'com.launchdarkly:launchdarkly-android-client',
    'com.launchdarkly:launchdarkly-client',
    'no.finn.unleash:unleash-client-java',
    'cc.soham:toggle','org.togglz:togglz-core',
    'org.ff4j:ff4j-core','com.tacitknowledge.flip:core',
    'com.springernature:bandiera-client-scala_2.12',
    'com.springernature:bandiera-client-scala_2.11',

    -- ❹  Go modules
    'github.com/launchdarkly/go-client',
    'github.com/unleash/unleash-client-go',
    'github.com/xchapter7x/toggle','github.com/vsco/dcdr',

    -- ❺  Python – PyPI
    'unleashclient','ldclient-py','flask-featureflags','gutter',
    'feature_ramp','flagon','django-waffle','gargoyle','gargoyle-yplan',

    -- ❻  PHP – Packagist
    'launchdarkly/launchdarkly-php','dzunke/feature-flags-bundle',
    'opensoft/rollout','npg/bandiera-client-php',

    -- ❼  Ruby – Rubygems
    'unleash','ldclient-rb','rollout','feature_flipper','flip',
    'setler','bandiera-client','feature','flipper',

    -- ❽  CocoaPods / Carthage (iOS)  & misc spellings
    'launchdarkly','launchdarkly-android-client',
    'launchdarkly-nodeutils','ldclient'
  ]) AS lib
)

SELECT DISTINCT
       rd.repository_name_with_owner        AS repository_full_name,
       COALESCE(r.host_type, rd.host_type)  AS host_type,
       r.size * 1024                        AS size_bytes,
       r.language                           AS repository_language,
       r.fork_source_name_with_owner,
       r.updated_timestamp                  AS repository_updated_timestamp,
       rd.dependency_project_name           AS artifact_name,
       p.name                               AS library_name,
       p.platform                           AS library_platform,
       p.language                           AS library_languages
FROM   `bigquery-public-data.libraries_io.repository_dependencies` AS rd
LEFT  JOIN `bigquery-public-data.libraries_io.repositories`        AS r
       ON  r.name_with_owner = rd.repository_name_with_owner
LEFT  JOIN `bigquery-public-data.libraries_io.projects`            AS p
       ON  p.id = rd.dependency_project_id
WHERE  LOWER(rd.dependency_project_name) IN (SELECT lib_name FROM feature_toggle_libs)
ORDER  BY repository_updated_timestamp DESC
LIMIT 1000;