WITH feature_toggle_libs AS (
    SELECT
        column1 AS "artifact_name",
        column2 AS "library_name",
        column3 AS "platform",
        column4 AS "languages"
    FROM VALUES
        -- .NET Libraries
        ('Unleash.FeatureToggle.Client', 'unleash-client-dotnet', 'NuGet', 'C#, Visual Basic'),
        ('unleash.client', 'unleash-client', 'NuGet', 'C#, Visual Basic'),
        ('LaunchDarkly.Client', 'launchdarkly', 'NuGet', 'C#, Visual Basic'),
        ('NFeature', 'NFeature', 'NuGet', 'C#, Visual Basic'),
        ('FeatureToggle', 'FeatureToggle', 'NuGet', 'C#, Visual Basic'),
        ('FeatureSwitcher', 'FeatureSwitcher', 'NuGet', 'C#, Visual Basic'),
        ('Toggler', 'Toggler', 'NuGet', 'C#, Visual Basic'),
        -- Go Libraries
        ('github.com/launchdarkly/go-client', 'launchdarkly', 'Go', 'Go'),
        ('github.com/xchapter7x/toggle', 'Toggle', 'Go', 'Go'),
        ('github.com/vsco/dcdr', 'dcdr', 'Go', 'Go'),
        ('github.com/unleash/unleash-client-go', 'unleash-client-go', 'Go', 'Go'),
        -- JavaScript/TypeScript Libraries
        ('unleash-client', 'unleash-client-node', 'NPM', 'JavaScript, TypeScript'),
        ('ldclient-js', 'launchdarkly', 'NPM', 'JavaScript, TypeScript'),
        ('ember-feature-flags', 'ember-feature-flags', 'NPM', 'JavaScript, TypeScript'),
        ('feature-toggles', 'feature-toggles', 'NPM', 'JavaScript, TypeScript'),
        ('@paralleldrive/react-feature-toggles', 'React Feature Toggles', 'NPM', 'JavaScript, TypeScript'),
        ('ldclient-node', 'launchdarkly', 'NPM', 'JavaScript, TypeScript'),
        ('flipit', 'flipit', 'NPM', 'JavaScript, TypeScript'),
        ('fflip', 'fflip', 'NPM', 'JavaScript, TypeScript'),
        ('bandiera-client', 'Bandiera', 'NPM', 'JavaScript, TypeScript'),
        ('@flopflip/react-redux', 'flopflip', 'NPM', 'JavaScript, TypeScript'),
        ('@flopflip/react-broadcast', 'flopflip', 'NPM', 'JavaScript, TypeScript'),
        -- Maven/Kotlin/Java Libraries
        ('com.launchdarkly:launchdarkly-android-client', 'launchdarkly', 'Maven', 'Kotlin, Java'),
        ('cc.soham:toggle', 'Toggle', 'Maven', 'Kotlin, Java'),
        ('no.finn.unleash:unleash-client-java', 'unleash-client-java', 'Maven', 'Kotlin, Java'),
        ('com.launchdarkly:launchdarkly-client', 'launchdarkly', 'Maven', 'Kotlin, Java'),
        ('org.togglz:togglz-core', 'Togglz', 'Maven', 'Kotlin, Java'),
        ('org.ff4j:ff4j-core', 'FF4J', 'Maven', 'Kotlin, Java'),
        ('com.tacitknowledge.flip:core', 'Flip', 'Maven', 'Kotlin, Java'),
        -- iOS Libraries
        ('LaunchDarkly', 'launchdarkly', 'CocoaPods', 'Objective-C, Swift'),
        ('launchdarkly/ios-client', 'launchdarkly', 'Carthage', 'Objective-C, Swift'),
        -- PHP Libraries
        ('launchdarkly/launchdarkly-php', 'launchdarkly', 'Packagist', 'PHP'),
        ('dzunke/feature-flags-bundle', 'Symfony FeatureFlagsBundle', 'Packagist', 'PHP'),
        ('opensoft/rollout', 'rollout', 'Packagist', 'PHP'),
        ('npg/bandiera-client-php', 'Bandiera', 'Packagist', 'PHP'),
        -- Python Libraries
        ('UnleashClient', 'unleash-client-python', 'Pypi', 'Python'),
        ('ldclient-py', 'launchdarkly', 'Pypi', 'Python'),
        ('Flask-FeatureFlags', 'Flask FeatureFlags', 'Pypi', 'Python'),
        ('gutter', 'Gutter', 'Pypi', 'Python'),
        ('feature_ramp', 'Feature Ramp', 'Pypi', 'Python'),
        ('flagon', 'flagon', 'Pypi', 'Python'),
        ('django-waffle', 'Waffle', 'Pypi', 'Python'),
        ('gargoyle', 'Gargoyle', 'Pypi', 'Python'),
        ('gargoyle-yplan', 'Gargoyle', 'Pypi', 'Python'),
        -- Ruby Libraries
        ('unleash', 'unleash-client-ruby', 'Rubygems', 'Ruby'),
        ('ldclient-rb', 'launchdarkly', 'Rubygems', 'Ruby'),
        ('rollout', 'rollout', 'Rubygems', 'Ruby'),
        ('feature_flipper', 'FeatureFlipper', 'Rubygems', 'Ruby'),
        ('flip', 'Flip', 'Rubygems', 'Ruby'),
        ('setler', 'Setler', 'Rubygems', 'Ruby'),
        ('feature', 'Feature', 'Rubygems', 'Ruby'),
        ('flipper', 'Flipper', 'Rubygems', 'Ruby'),
        -- Scala Libraries
        ('com.springernature:bandiera-client-scala_2.12', 'Bandiera', 'Maven', 'Scala'),
        ('com.springernature:bandiera-client-scala_2.11', 'Bandiera', 'Maven', 'Scala')
)
SELECT
    r."name_with_owner" AS repository_full_name,
    r."host_type",
    r."size"::INTEGER AS size_bytes,
    r."language",
    COALESCE(r."fork_source_name_with_owner", '') AS fork_source_name_with_owner,
    r."updated_timestamp",
    d."dependency_name" AS feature_toggle_artifact_name,
    ft."library_name" AS feature_toggle_library_name,
    ft."languages" AS feature_toggle_languages
FROM
    "LIBRARIES_IO"."LIBRARIES_IO"."REPOSITORIES" r
JOIN
    "LIBRARIES_IO"."LIBRARIES_IO"."PROJECTS" p ON r."id" = p."repository_id"
JOIN
    "LIBRARIES_IO"."LIBRARIES_IO"."DEPENDENCIES" d ON p."id" = d."project_id"
JOIN
    feature_toggle_libs ft ON d."dependency_name" = ft."artifact_name" AND d."dependency_platform" = ft."platform"
LIMIT 100;