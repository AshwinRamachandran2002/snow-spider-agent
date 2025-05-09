WITH feature_toggle_libs AS (
    SELECT column1 AS artifact_name,
           column2 AS library_name,
           column3 AS library_languages
    FROM VALUES
        ('Unleash.FeatureToggle.Client','unleash-client-dotnet','C#, Visual Basic'),
        ('unleash.client','unleash-client','C#, Visual Basic'),
        ('LaunchDarkly.Client','launchdarkly','.NET (C#, VB)'),
        ('NFeature','NFeature','C#, Visual Basic'),
        ('FeatureToggle','FeatureToggle','C#, Visual Basic'),
        ('FeatureSwitcher','FeatureSwitcher','C#, Visual Basic'),
        ('Toggler','Toggler','C#, Visual Basic'),
        ('github.com/launchdarkly/go-client','launchdarkly','Go'),
        ('github.com/xchapter7x/toggle','Toggle','Go'),
        ('github.com/vsco/dcdr','dcdr','Go'),
        ('github.com/unleash/unleash-client-go','unleash-client-go','Go'),
        ('unleash-client','unleash-client-node','JavaScript, TypeScript'),
        ('ldclient-js','launchdarkly','JavaScript, TypeScript'),
        ('ember-feature-flags','ember-feature-flags','JavaScript, TypeScript'),
        ('feature-toggles','feature-toggles','JavaScript, TypeScript'),
        ('@paralleldrive/react-feature-toggles','React Feature Toggles','JavaScript, TypeScript'),
        ('ldclient-node','launchdarkly','JavaScript, TypeScript'),
        ('flipit','flipit','JavaScript, TypeScript'),
        ('fflip','fflip','JavaScript, TypeScript'),
        ('bandiera-client','Bandiera','JavaScript, TypeScript'),
        ('@flopflip/react-redux','flopflip','JavaScript, TypeScript'),
        ('@flopflip/react-broadcast','flopflip','JavaScript, TypeScript'),
        ('com.launchdarkly:launchdarkly-android-client','launchdarkly','Java, Kotlin'),
        ('cc.soham:toggle','toggle','Java, Kotlin'),
        ('no.finn.unleash:unleash-client-java','unleash-client-java','Java, Kotlin'),
        ('com.launchdarkly:launchdarkly-client','launchdarkly','Java, Kotlin'),
        ('org.togglz:togglz-core','Togglz','Java, Kotlin'),
        ('org.ff4j:ff4j-core','FF4J','Java, Kotlin'),
        ('com.tacitknowledge.flip:core','Flip','Java, Kotlin'),
        ('LaunchDarkly','launchdarkly','Objective-C, Swift'),
        ('launchdarkly/ios-client','launchdarkly','Objective-C, Swift'),
        ('launchdarkly/launchdarkly-php','launchdarkly','PHP'),
        ('dzunke/feature-flags-bundle','Symfony FeatureFlagsBundle','PHP'),
        ('opensoft/rollout','rollout','PHP'),
        ('npg/bandiera-client-php','Bandiera','PHP'),
        ('UnleashClient','unleash-client-python','Python'),
        ('ldclient-py','launchdarkly','Python'),
        ('Flask-FeatureFlags','Flask FeatureFlags','Python'),
        ('gutter','Gutter','Python'),
        ('feature_ramp','Feature Ramp','Python'),
        ('flagon','flagon','Python'),
        ('django-waffle','Waffle','Python'),
        ('gargoyle','Gargoyle','Python'),
        ('gargoyle-yplan','Gargoyle','Python'),
        ('unleash','unleash-client-ruby','Ruby'),
        ('ldclient-rb','launchdarkly','Ruby'),
        ('rollout','rollout','Ruby'),
        ('feature_flipper','FeatureFlipper','Ruby'),
        ('flip','Flip','Ruby'),
        ('setler','Setler','Ruby'),
        ('bandiera-client','Bandiera','Ruby'),
        ('feature','Feature','Ruby'),
        ('flipper','Flipper','Ruby'),
        ('com.springernature:bandiera-client-scala_2.12','Bandiera','Scala'),
        ('com.springernature:bandiera-client-scala_2.11','Bandiera','Scala')
),
repo_with_feature_toggle AS (
    SELECT
        r."name_with_owner"            AS repository_name_with_owner,
        r."host_type",
        r."size",
        r."language"                   AS primary_language,
        r."fork_source_name_with_owner",
        r."updated_timestamp"          AS repo_updated_timestamp,
        f.library_name                 AS feature_library_name,
        f.artifact_name                AS feature_artifact_name,
        f.library_languages
    FROM LIBRARIES_IO.LIBRARIES_IO.REPOSITORY_DEPENDENCIES rd
    JOIN feature_toggle_libs f
         ON LOWER(rd."dependency_project_name") = LOWER(f.artifact_name)
    JOIN LIBRARIES_IO.LIBRARIES_IO.REPOSITORIES r
         ON rd."repository_id" = r."id"
)
SELECT *
FROM repo_with_feature_toggle
ORDER BY repo_updated_timestamp DESC NULLS LAST;