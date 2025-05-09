WITH latest_release AS (
    SELECT
        "Name"      AS "Package",
        "Version",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY ("VersionInfo":"Ordinal"::NUMBER) DESC NULLS LAST
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND COALESCE("VersionInfo":"IsRelease"::BOOLEAN, FALSE) = TRUE
),
pkg_project AS (
    SELECT
        lr."Package",
        lr."Version",
        p2p."ProjectName"
    FROM latest_release lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT p2p
      ON lr."Package" = p2p."Name"
     AND lr."Version" = p2p."Version"
    WHERE lr.rn = 1
      AND p2p."ProjectType" = 'GITHUB'
),
package_stars AS (
    SELECT
        pp."Package",
        pp."Version",
        MAX(pr."StarsCount") AS "StarsCount"
    FROM pkg_project pp
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS pr
      ON pr."Type" = 'GITHUB'
     AND pr."Name" = pp."ProjectName"
    GROUP BY
        pp."Package",
        pp."Version"
)
SELECT
    "Package",
    "Version"
FROM package_stars
ORDER BY
    "StarsCount" DESC NULLS LAST
LIMIT 8;