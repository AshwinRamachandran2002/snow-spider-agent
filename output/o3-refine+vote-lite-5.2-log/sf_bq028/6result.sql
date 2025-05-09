WITH latest_release AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY 
                    COALESCE(("VersionInfo":"IsRelease")::BOOLEAN, FALSE) DESC,
                    COALESCE(("VersionInfo":"Ordinal")::NUMBER, 0)    DESC,
                    "SnapshotAt"                                     DESC
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND COALESCE(("VersionInfo":"IsRelease")::BOOLEAN, FALSE)
    )
    WHERE rn = 1
),
latest_projects AS (
    SELECT
        "Name"       AS "ProjectName",
        "StarsCount"
    FROM (
        SELECT
            "Name",
            "StarsCount",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "SnapshotAt" DESC
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
        WHERE "Type" = 'GITHUB'
    )
    WHERE rn = 1
)
SELECT
    lr."Name"                     AS "Package",
    lr."Version"                  AS "Version",
    MAX(lp."StarsCount")          AS "StarsCount"
FROM latest_release            lr
JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pv2p
  ON pv2p."System"  = 'NPM'
 AND lr."Name"      = pv2p."Name"
 AND lr."Version"   = pv2p."Version"
JOIN latest_projects           lp
  ON lp."ProjectName" = pv2p."ProjectName"
GROUP BY
    lr."Name",
    lr."Version"
ORDER BY
    "StarsCount" DESC NULLS LAST,
    lr."Name"
LIMIT 8;