WITH latest_release_pkg AS (   -- latest release version for every NPM package
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
            ) = 1
),
pkg_project AS (              -- map those package versions to their GitHub project
    SELECT
        l."Name"      AS "Package",
        l."Version",
        pvtp."ProjectName"
    FROM latest_release_pkg l
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pvtp
      ON pvtp."System"      = 'NPM'
     AND pvtp."Name"        = l."Name"
     AND pvtp."Version"     = l."Version"
     AND pvtp."ProjectType" = 'GITHUB'
),
project_stars AS (            -- latest snapshot of each GitHub project’s star count
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
    pp."Package",
    pp."Version",
    ps."StarsCount"
FROM pkg_project pp
JOIN project_stars ps
  ON ps."ProjectName" = pp."ProjectName"
ORDER BY
    ps."StarsCount" DESC NULLS LAST,
    pp."Package"
LIMIT 8;