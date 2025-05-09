WITH latest_release AS (   -- latest *release* version for every NPM package
    SELECT "Name", "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "SnapshotAt" DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND COALESCE("VersionInfo":"IsRelease"::BOOLEAN, TRUE)
    )
    WHERE rn = 1
),
proj_snap AS (             -- most‑recent GitHub‑projects snapshot timestamp
    SELECT MAX("SnapshotAt") AS snap
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
),
projects_latest AS (       -- GitHub repo stats from that snapshot
    SELECT "Name", "StarsCount"
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
    WHERE  "SnapshotAt" = (SELECT snap FROM proj_snap)
      AND  "Type" = 'GITHUB'
),
pkg_repo AS (              -- map package version → GitHub repo
    SELECT "Name", "Version", "ProjectName"
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT
    WHERE  "System" = 'NPM'
      AND  "ProjectType" = 'GITHUB'
),
pkg_stars AS (             -- derive star counts per package
    SELECT
        lr."Name",
        lr."Version",
        MAX(pl."StarsCount") AS github_stars
    FROM   latest_release  lr
    JOIN   pkg_repo        pr ON lr."Name" = pr."Name"
                              AND lr."Version" = pr."Version"
    JOIN   projects_latest pl ON pr."ProjectName" = pl."Name"
    GROUP  BY lr."Name", lr."Version"
),
ranked AS (
    SELECT
        "Name",
        "Version",
        github_stars,
        ROW_NUMBER() OVER (ORDER BY github_stars DESC NULLS LAST, "Name") AS rn
    FROM pkg_stars
)
SELECT
    "Name"        AS package_name,
    "Version"     AS latest_version,
    github_stars
FROM   ranked
WHERE  rn <= 8
ORDER  BY github_stars DESC NULLS LAST,
          package_name;