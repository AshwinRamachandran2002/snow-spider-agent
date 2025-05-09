WITH feature_toggle_libraries AS (
  SELECT
    column1 AS "artifact_name",
    column2 AS "library_name",
    column3 AS "languages"
  FROM (
    VALUES
      ('Unleash.FeatureToggle.Client', 'unleash-client-dotnet', 'C#, Visual Basic'),
      ('unleash.client', 'unleash-client', 'C#, Visual Basic'),
      ('LaunchDarkly.Client', 'launchdarkly', 'C#, Visual Basic'),
      ('NFeature', 'NFeature', 'C#, Visual Basic'),
      ('FeatureToggle', 'FeatureToggle', 'C#, Visual Basic'),
      ('FeatureSwitcher', 'FeatureSwitcher', 'C#, Visual Basic'),
      ('Toggler', 'Toggler', 'C#, Visual Basic'),
      ('github.com/launchdarkly/go-client', 'launchdarkly', 'Go'),
      ('github.com/xchapter7x/toggle', 'Toggle', 'Go'),
      ('github.com/vsco/dcdr', 'dcdr', 'Go'),
      ('github.com/unleash/unleash-client-go', 'unleash-client-go', 'Go'),
      ('unleash-client', 'unleash-client-node', 'JavaScript, TypeScript'),
      ('ldclient-js', 'launchdarkly', 'JavaScript, TypeScript'),
      ('ember-feature-flags', 'ember-feature-flags', 'JavaScript, TypeScript'),
      ('feature-toggles', 'feature-toggles', 'JavaScript, TypeScript'),
      ('@paralleldrive/react-feature-toggles', 'React Feature Toggles', 'JavaScript, TypeScript'),
      ('ldclient-node', 'launchdarkly', 'JavaScript, TypeScript'),
      ('flipit', 'flipit', 'JavaScript, TypeScript'),
      ('fflip', 'fflip', 'JavaScript, TypeScript'),
      ('bandiera-client', 'Bandiera', 'JavaScript, TypeScript'),
      ('@flopflip/react-redux', 'flopflip', 'JavaScript, TypeScript'),
      ('@flopflip/react-broadcast', 'flopflip', 'JavaScript, TypeScript'),
      ('com.launchdarkly:launchdarkly-android-client', 'launchdarkly', 'Kotlin, Java'),
      ('cc.soham:toggle', 'toggle', 'Kotlin, Java'),
      ('no.finn.unleash:unleash-client-java', 'unleash-client-java', 'Kotlin, Java'),
      ('com.launchdarkly:launchdarkly-client', 'launchdarkly', 'Kotlin, Java'),
      ('org.togglz:togglz-core', 'Togglz', 'Kotlin, Java'),
      ('org.ff4j:ff4j-core', 'FF4J', 'Kotlin, Java'),
      ('com.tacitknowledge.flip:core', 'Flip', 'Kotlin, Java'),
      ('ldclient-py', 'launchdarkly', 'Python'),
      ('UnleashClient', 'unleash-client-python', 'Python'),
      ('Flask-FeatureFlags', 'Flask FeatureFlags', 'Python'),
      ('gutter', 'Gutter', 'Python'),
      ('feature_ramp', 'Feature Ramp', 'Python'),
      ('django-waffle', 'Waffle', 'Python'),
      ('unleash', 'unleash-client-ruby', 'Ruby'),
      ('ldclient-rb', 'launchdarkly', 'Ruby'),
      ('rollout', 'rollout', 'Ruby'),
      ('feature_flipper', 'FeatureFlipper', 'Ruby'),
      ('flip', 'Flip', 'Ruby'),
      ('setler', 'Setler', 'Ruby'),
      ('feature', 'Feature', 'Ruby'),
      ('flipper', 'Flipper', 'Ruby'),
      ('bandiera-client', 'Bandiera', 'Ruby')
  )
)
SELECT DISTINCT
  r."name_with_owner" AS repository_full_name,
  r."host_type",
  r."size" AS size_bytes,
  r."language",
  r."fork_source_name_with_owner",
  r."updated_timestamp",
  ft."artifact_name" AS feature_toggle_artifact_name,
  ft."library_name" AS feature_toggle_library_name,
  ft."languages" AS feature_toggle_languages
FROM "LIBRARIES_IO"."LIBRARIES_IO"."REPOSITORY_DEPENDENCIES" rd
INNER JOIN feature_toggle_libraries ft ON rd."dependency_project_name" = ft."artifact_name"
INNER JOIN "LIBRARIES_IO"."LIBRARIES_IO"."REPOSITORIES" r ON rd."repository_id" = r."id";