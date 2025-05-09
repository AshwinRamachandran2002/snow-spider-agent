WITH latest_release AS (   -- latest released version of every NPM package
    SELECT
        pv."Name",
        pv."Version",
        row_number() OVER (
            PARTITION BY pv."Name"
            ORDER BY COALESCE(pv."UpstreamPublishedAt", pv."SnapshotAt") DESC NULLS LAST
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS AS pv
    WHERE pv."System" = 'NPM'
      AND (pv."VersionInfo":"IsRelease")::BOOLEAN = TRUE
),
latest_repo_snapshot AS (  -- most‑recent snapshot for every GitHub repo
    SELECT
        p."Name"              AS "Repo",
        p."StarsCount",
        row_number() OVER (
            PARTITION BY p."Name"
            ORDER BY p."SnapshotAt" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS AS p
    WHERE p."Type" = 'GITHUB'
),
pkg_repo_stars AS (       -- map latest package versions to repo stars
    SELECT
        lr."Name"     AS "Package",
        lr."Version",
        rs."StarsCount"
    FROM latest_release AS lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT AS pr
      ON  lr."Name"    = pr."Name"
      AND lr."Version" = pr."Version"
      AND pr."System"  = 'NPM'
      AND pr."ProjectType" = 'GITHUB'
    JOIN latest_repo_snapshot AS rs
      ON pr."ProjectName" = rs."Repo"
    WHERE lr.rn = 1
      AND rs.rn = 1
)
SELECT
    "Package",
    "Version"
FROM (
    SELECT
        "Package",
        "Version",
        MAX("StarsCount") AS "Stars"
    FROM pkg_repo_stars
    GROUP BY "Package", "Version"
) ranked
ORDER BY "Stars" DESC NULLS LAST, "Package"
LIMIT 8;