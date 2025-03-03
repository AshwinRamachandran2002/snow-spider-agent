WITH feature_toggles AS (
    SELECT 'Unleash.FeatureToggle.Client' AS "artifact_name", 'unleash-client-dotnet' AS "library_name", 'nuget' AS "platform", 'C#, Visual Basic' AS "languages"
    UNION ALL
    SELECT 'unleash.client', 'unleash-client', 'nuget', 'C#, Visual Basic'
    UNION ALL
    SELECT 'LaunchDarkly.Client', 'launchdarkly', 'nuget', 'C#, Visual Basic'
    UNION ALL
    SELECT 'NFeature', 'NFeature', 'nuget', 'C#, Visual Basic'
    UNION ALL
    SELECT 'FeatureToggle', 'FeatureToggle', 'nuget', 'C#, Visual Basic'
    UNION ALL
    SELECT 'FeatureSwitcher', 'FeatureSwitcher', 'nuget', 'C#, Visual Basic'
    UNION ALL
    SELECT 'Toggler', 'Toggler', 'nuget', 'C#, Visual Basic'
    UNION ALL
    -- Go Libraries
    SELECT 'github.com/launchdarkly/go-client', 'launchdarkly', 'go', 'Go'
    UNION ALL
    SELECT 'github.com/xchapter7x/toggle', 'Toggle', 'go', 'Go'
    UNION ALL
    SELECT 'github.com/vsco/dcdr', 'dcdr', 'go', 'Go'
    UNION ALL
    SELECT 'github.com/unleash/unleash-client-go', 'unleash-client-go', 'go', 'Go'
    UNION ALL
    -- JavaScript/TypeScript Libraries
    SELECT 'unleash-client', 'unleash-client-node', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'ldclient-js', 'launchdarkly', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'ember-feature-flags', 'ember-feature-flags', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'feature-toggles', 'feature-toggles', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT '@paralleldrive/react-feature-toggles', 'React Feature Toggles', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'flipit', 'flipit', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'fflip', 'fflip', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT 'bandiera-client', 'Bandiera', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT '@flopflip/react-redux', 'flopflip', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    SELECT '@flopflip/react-broadcast', 'flopflip', 'npm', 'JavaScript, TypeScript'
    UNION ALL
    -- Maven/Kotlin/Java Libraries
    SELECT 'no.finn.unleash:unleash-client-java', 'unleash-client-java', 'maven', 'Kotlin, Java'
    UNION ALL
    SELECT 'com.launchdarkly:launchdarkly-client', 'launchdarkly', 'maven', 'Kotlin, Java'
    UNION ALL
    SELECT 'org.togglz:togglz-core', 'Togglz', 'maven', 'Kotlin, Java'
    UNION ALL
    SELECT 'org.ff4j:ff4j-core', 'FF4J', 'maven', 'Kotlin, Java'
    UNION ALL
    SELECT 'com.tacitknowledge.flip:core', 'Flip', 'maven', 'Kotlin, Java'
    UNION ALL
    -- PHP Libraries (Packagist)
    SELECT 'launchdarkly/launchdarkly-php', 'launchdarkly', 'packagist', 'PHP'
    UNION ALL
    SELECT 'dzunke/feature-flags-bundle', 'Symfony FeatureFlagsBundle', 'packagist', 'PHP'
    UNION ALL
    SELECT 'opensoft/rollout', 'rollout', 'packagist', 'PHP'
    UNION ALL
    SELECT 'npg/bandiera-client-php', 'Bandiera', 'packagist', 'PHP'
    UNION ALL
    -- Python Libraries (Pypi)
    SELECT 'UnleashClient', 'unleash-client-python', 'pypi', 'Python'
    UNION ALL
    SELECT 'ldclient-py', 'launchdarkly', 'pypi', 'Python'
    UNION ALL
    SELECT 'Flask-FeatureFlags', 'Flask FeatureFlags', 'pypi', 'Python'
    UNION ALL
    SELECT 'gutter', 'Gutter', 'pypi', 'Python'
    UNION ALL
    SELECT 'feature_ramp', 'Feature Ramp', 'pypi', 'Python'
    UNION ALL
    SELECT 'flagon', 'flagon', 'pypi', 'Python'
    UNION ALL
    SELECT 'django-waffle', 'Waffle', 'pypi', 'Python'
    UNION ALL
    SELECT 'gargoyle', 'Gargoyle', 'pypi', 'Python'
    UNION ALL
    SELECT 'gargoyle-yplan', 'Gargoyle', 'pypi', 'Python'
    UNION ALL
    -- Ruby Libraries (Rubygems)
    SELECT 'unleash', 'unleash-client-ruby', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'ldclient-rb', 'launchdarkly', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'rollout', 'rollout', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'feature_flipper', 'FeatureFlipper', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'flip', 'Flip', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'setler', 'Setler', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'feature', 'Feature', 'rubygems', 'Ruby'
    UNION ALL
    SELECT 'flipper', 'Flipper', 'rubygems', 'Ruby'
)
SELECT r."name_with_owner" AS "repository_full_name",
       r."host_type",
       r."size" AS "size_bytes",
       r."language",
       r."fork_source_name_with_owner",
       r."updated_timestamp",
       rd."dependency_project_name" AS "feature_toggle_artifact_name",
       ft."library_name" AS "feature_toggle_library_name",
       ft."languages" AS "feature_toggle_languages"
FROM "LIBRARIES_IO"."LIBRARIES_IO"."REPOSITORIES" r
JOIN "LIBRARIES_IO"."LIBRARIES_IO"."REPOSITORY_DEPENDENCIES" rd
  ON rd."repository_id" = r."id"
JOIN feature_toggles ft
  ON LOWER(rd."dependency_project_name") = LOWER(ft."artifact_name")
  AND LOWER(rd."manifest_platform") = LOWER(ft."platform")
ORDER BY r."updated_timestamp" DESC NULLS LAST;