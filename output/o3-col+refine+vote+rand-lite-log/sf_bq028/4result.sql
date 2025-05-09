WITH latest_release AS (               -- latest *released* version per NPM package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "VersionInfo":"Ordinal"::NUMBER                            AS "ord",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
project_stars AS (                     -- most-recent GitHub star count per repo
    SELECT
        "Name"        AS "Repo",
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
),
pkg_repo AS (                          -- map package/version → GitHub repo
    SELECT
        lr."Name",
        lr."Version",
        pvt."ProjectName"                          AS "Repo"
    FROM latest_release               lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pvt
         ON  lr."Name"    = pvt."Name"
         AND lr."Version" = pvt."Version"
         AND pvt."System" = 'NPM'
    WHERE pvt."ProjectType" = 'GITHUB'
)
SELECT
    pr."Name"                AS "Package",
    pr."Version",
    MAX(ps."StarsCount")     AS "GitHub_Stars"
FROM pkg_repo      pr
JOIN project_stars ps
  ON ps."Repo" = pr."Repo"
GROUP BY
    pr."Name",
    pr."Version"
ORDER BY
    "GitHub_Stars" DESC NULLS LAST
LIMIT 8;