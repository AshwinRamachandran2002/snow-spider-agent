WITH latest_release AS (    -- latest released version for every NPM package
    SELECT
        "Name",
        "Version",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY ("VersionInfo":"Ordinal")::INTEGER DESC NULLS LAST,
                     "SnapshotAt"                         DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
),
latest_release_pkgs AS (
    SELECT "Name", "Version"
    FROM   latest_release
    WHERE  rn = 1
),
project_latest AS (         -- most‑recent stars count per GitHub repo
    SELECT
        "Name",
        "StarsCount"
    FROM (
        SELECT
            "Name",
            "StarsCount",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "SnapshotAt" DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
        WHERE "Type" = 'GITHUB'
    )
    WHERE rn = 1
)
SELECT
    lr."Name",
    lr."Version",
    MAX(pl."StarsCount") AS "StarsCount"
FROM   latest_release_pkgs                       lr
JOIN   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pv
       ON  pv."System"      = 'NPM'
       AND pv."Name"        = lr."Name"
       AND pv."Version"     = lr."Version"
       AND pv."ProjectType" = 'GITHUB'
JOIN   project_latest                           pl
       ON  pl."Name" = pv."ProjectName"
GROUP BY lr."Name", lr."Version"
ORDER BY "StarsCount" DESC NULLS LAST,
         lr."Name"
LIMIT 8;