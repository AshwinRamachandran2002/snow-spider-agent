WITH latest_release_per_pkg AS (
    SELECT
        "Name",
        "Version",
        "SnapshotAt"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY "Name"
        ORDER BY "SnapshotAt" DESC
    ) = 1
),
npm_pkg_to_github AS (
    SELECT
        "Name",
        "Version",
        "ProjectName"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT
    WHERE "System"      = 'NPM'
      AND "ProjectType" = 'GITHUB'
),
latest_project_stats AS (
    SELECT
        "Name"        AS "ProjectName",
        "StarsCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
    WHERE "Type" = 'GITHUB'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY "Name"
        ORDER BY "SnapshotAt" DESC
    ) = 1
)
SELECT
    lr."Name"      AS "PackageName",
    lr."Version",
    lp."StarsCount"
FROM latest_release_per_pkg  lr
JOIN npm_pkg_to_github       pg  ON lr."Name" = pg."Name"
                               AND lr."Version" = pg."Version"
JOIN latest_project_stats    lp  ON lp."ProjectName" = pg."ProjectName"
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY lr."Name"
    ORDER BY lp."StarsCount" DESC NULLS LAST
) = 1
ORDER BY lp."StarsCount" DESC NULLS LAST
LIMIT 8;