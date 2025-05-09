WITH feature_toggle_libs AS (
    SELECT
        column1 AS artifact_name,
        column2 AS library_name,
        column3 AS platform,
        column4 AS library_languages
    FROM VALUES
        ('Unleash.FeatureToggle.Client',           'unleash-client-dotnet',        'NuGet',      'C#, Visual Basic'),
        ('unleash.client',                        'unleash-client',               'NuGet',      'C#, Visual Basic'),
        ('LaunchDarkly.Client',                   'launchdarkly',                 'NuGet',      'C#, Visual Basic'),
        ('NFeature',                              'NFeature',                     'NuGet',      'C#, Visual Basic'),
        ('FeatureToggle',                         'FeatureToggle',                'NuGet',      'C#, Visual Basic'),
        ('FeatureSwitcher',                       'FeatureSwitcher',              'NuGet',      'C#, Visual Basic'),
        ('Toggler',                               'Toggler',                      'NuGet',      'C#, Visual Basic'),

        ('github.com/launchdarkly/go-client',     'launchdarkly',                 'Go',         'Go'),
        ('github.com/xchapter7x/toggle',          'Toggle',                       'Go',         'Go'),
        ('github.com/vsco/dcdr',                  'dcdr',                         'Go',         'Go'),
        ('github.com/unleash/unleash-client-go',  'unleash-client-go',            'Go',         'Go'),

        ('unleash-client',                        'unleash-client-node',          'NPM',        'JavaScript, TypeScript'),
        ('ldclient-js',                           'launchdarkly',                 'NPM',        'JavaScript, TypeScript'),
        ('ember-feature-flags',                   'ember-feature-flags',          'NPM',        'JavaScript, TypeScript'),
        ('feature-toggles',                       'feature-toggles',              'NPM',        'JavaScript, TypeScript'),
        ('@paralleldrive/react-feature-toggles',  'React Feature Toggles',        'NPM',        'JavaScript, TypeScript'),
        ('ldclient-node',                         'launchdarkly',                 'NPM',        'JavaScript, TypeScript'),
        ('flipit',                                'flipit',                       'NPM',        'JavaScript, TypeScript'),
        ('fflip',                                 'fflip',                        'NPM',        'JavaScript, TypeScript'),
        ('bandiera-client',                       'Bandiera',                     'NPM',        'JavaScript, TypeScript'),
        ('@flopflip/react-redux',                 'flopflip',                     'NPM',        'JavaScript, TypeScript'),
        ('@flopflip/react-broadcast',             'flopflip',                     'NPM',        'JavaScript, TypeScript'),

        ('com.launchdarkly:launchdarkly-android-client', 'launchdarkly',          'Maven',      'Kotlin, Java'),
        ('cc.soham:toggle',                       'toggle',                       'Maven',      'Kotlin, Java'),
        ('no.finn.unleash:unleash-client-java',   'unleash-client-java',          'Maven',      'Kotlin, Java'),
        ('com.launchdarkly:launchdarkly-client',  'launchdarkly',                 'Maven',      'Kotlin, Java'),
        ('org.togglz:togglz-core',                'Togglz',                       'Maven',      'Kotlin, Java'),
        ('org.ff4j:ff4j-core',                    'FF4J',                         'Maven',      'Kotlin, Java'),
        ('com.tacitknowledge.flip:core',          'Flip',                         'Maven',      'Kotlin, Java'),
        ('com.springernature:bandiera-client-scala_2.12', 'Bandiera',            'Maven',      'Scala'),
        ('com.springernature:bandiera-client-scala_2.11', 'Bandiera',            'Maven',      'Scala'),

        ('LaunchDarkly',                          'launchdarkly',                 'CocoaPods',  'Objective-C, Swift'),
        ('launchdarkly/ios-client',               'launchdarkly',                 'Carthage',   'Objective-C, Swift'),

        ('launchdarkly/launchdarkly-php',         'launchdarkly',                 'Packagist',  'PHP'),
        ('dzunke/feature-flags-bundle',           'Symfony FeatureFlagsBundle',   'Packagist',  'PHP'),
        ('opensoft/rollout',                      'rollout',                      'Packagist',  'PHP'),
        ('npg/bandiera-client-php',               'Bandiera',                     'Packagist',  'PHP'),

        ('UnleashClient',                         'unleash-client-python',        'Pypi',       'Python'),
        ('ldclient-py',                           'launchdarkly',                 'Pypi',       'Python'),
        ('Flask-FeatureFlags',                    'Flask FeatureFlags',           'Pypi',       'Python'),
        ('gutter',                                'Gutter',                       'Pypi',       'Python'),
        ('feature_ramp',                          'Feature Ramp',                 'Pypi',       'Python'),
        ('flagon',                                'flagon',                       'Pypi',       'Python'),
        ('django-waffle',                         'Waffle',                       'Pypi',       'Python'),
        ('gargoyle',                              'Gargoyle',                     'Pypi',       'Python'),
        ('gargoyle-yplan',                        'Gargoyle',                     'Pypi',       'Python'),

        ('unleash',                               'unleash-client-ruby',          'Rubygems',   'Ruby'),
        ('ldclient-rb',                           'launchdarkly',                 'Rubygems',   'Ruby'),
        ('rollout',                               'rollout',                      'Rubygems',   'Ruby'),
        ('feature_flipper',                       'FeatureFlipper',               'Rubygems',   'Ruby'),
        ('flip',                                  'Flip',                         'Rubygems',   'Ruby'),
        ('setler',                                'Setler',                       'Rubygems',   'Ruby'),
        ('bandiera-client',                       'Bandiera',                     'Rubygems',   'Ruby'),
        ('feature',                               'Feature',                      'Rubygems',   'Ruby'),
        ('flipper',                               'Flipper',                      'Rubygems',   'Ruby')
)

SELECT
    r."name_with_owner"          AS repository_full_name,
    r."host_type"                AS hosting_platform_type,
    r."size"                     AS repository_size_bytes,
    r."language"                 AS primary_language,
    r."fork_source_name_with_owner" AS fork_source_name_with_owner,
    r."updated_timestamp"        AS repository_updated_timestamp,
    f.artifact_name,
    f.library_name,
    f.library_languages
FROM
    LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES d
    JOIN LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES       r
         ON r."id" = d."repository_id"
    JOIN feature_toggle_libs                          f
         ON LOWER(d."dependency_project_name") = LOWER(f.artifact_name)
ORDER BY
    r."updated_timestamp" DESC NULLS LAST;