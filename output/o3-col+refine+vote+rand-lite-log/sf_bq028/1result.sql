WITH released_npm_versions AS (
    SELECT
        pv."Name"                                  AS "PackageName",
        pv."Version",
        pv."VersionInfo":"Ordinal"::NUMBER         AS "Ordinal",
        pvtp."ProjectName"                         AS "GitHubRepo",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC
        )                                          AS rn_pkg
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"         pv
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONTOPROJECT" pvtp
      ON  pv."System"  = pvtp."System"
      AND pv."Name"    = pvtp."Name"
      AND pv."Version" = pvtp."Version"
    WHERE pv."System" = 'NPM'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE         -- only official releases
      AND pvtp."ProjectType" = 'GITHUB'                        -- only GitHub projects
),
latest_releases AS (
    SELECT *
    FROM released_npm_versions
    WHERE rn_pkg = 1                                           -- keep latest release per package
),
latest_project_stats AS (
    SELECT
        pr."Name"                       AS "GitHubRepo",
        pr."StarsCount",
        ROW_NUMBER() OVER (
            PARTITION BY pr."Name"
            ORDER BY pr."SnapshotAt" DESC
        )                               AS rn_repo
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PROJECTS" pr
    WHERE pr."Type" = 'GITHUB'
),
current_project_stats AS (
    SELECT *
    FROM latest_project_stats
    WHERE rn_repo = 1                                           -- most recent snapshot per repo
)
SELECT
    lr."PackageName",
    lr."Version",
    cps."StarsCount"
FROM latest_releases lr
JOIN current_project_stats cps
  ON lr."GitHubRepo" = cps."GitHubRepo"
ORDER BY cps."StarsCount" DESC NULLS LAST
LIMIT 8;