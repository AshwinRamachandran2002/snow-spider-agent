WITH latest_release AS (          -- 1. keep only the latest *released* version per NPM package
    SELECT
        pv."Name",
        pv."Version",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST,
                     pv."SnapshotAt"                    DESC
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
pkg_proj AS (                     -- 2. map those package versions to their GitHub projects
    SELECT
        lr."Name",
        lr."Version",
        ptp."ProjectName"
    FROM latest_release lr
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" ptp
         ON  lr."Name"    = ptp."Name"
         AND lr."Version" = ptp."Version"
         AND ptp."System" = 'NPM'
         AND ptp."ProjectType" = 'GITHUB'
    WHERE lr.rn = 1
),
project_stars AS (                -- 3. keep the most-recent star count per GitHub repository
    SELECT
        pr."Name"        AS "ProjectName",
        pr."StarsCount",
        ROW_NUMBER() OVER (
            PARTITION BY pr."Name"
            ORDER BY pr."SnapshotAt" DESC
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pr
    WHERE pr."Type" = 'GITHUB'
)
SELECT                              -- 4. top-8 packages by GitHub stars
    pp."Name"      AS "Package",
    pp."Version",
    ps."StarsCount"
FROM pkg_proj      pp
JOIN project_stars ps
     ON ps."ProjectName" = pp."ProjectName"
WHERE ps.rn = 1
ORDER BY ps."StarsCount" DESC NULLS LAST
LIMIT 8;