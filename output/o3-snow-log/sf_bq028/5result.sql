/* Top 8 most-starred NPM packages (latest release version only) */
WITH latest_github_projects AS (   -- keep latest snapshot per GitHub repo
    SELECT
        "Name",
        "StarsCount"
    FROM (
        SELECT
            "Name",
            "StarsCount",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "SnapshotAt" DESC) AS rn
        FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS"
        WHERE "Type" = 'GITHUB'
    )
    WHERE rn = 1
),
latest_release_npm AS (           -- keep latest *released* version per NPM package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC) AS rn
        FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
        WHERE "System" = 'NPM'
          AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
pkg_to_repo AS (                  -- map packages to GitHub projects
    SELECT DISTINCT
        lr."Name"      AS "PkgName",
        lr."Version",
        pv2p."ProjectName"
    FROM latest_release_npm  lr
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pv2p
          ON lr."Name" = pv2p."Name"
    WHERE pv2p."ProjectType" = 'GITHUB'
)
SELECT
    ptr."PkgName",
    ptr."Version",
    MAX(lgp."StarsCount") AS "StarsCount"
FROM pkg_to_repo         ptr
JOIN latest_github_projects lgp
     ON lgp."Name" = ptr."ProjectName"
GROUP BY
    ptr."PkgName",
    ptr."Version"
ORDER BY
    "StarsCount" DESC NULLS LAST
LIMIT 8;