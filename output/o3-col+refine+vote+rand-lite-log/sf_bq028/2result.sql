WITH LatestRelease AS (
    SELECT
        "Name",
        "Version",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY ("VersionInfo":"Ordinal"::NUMBER) DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND ("VersionInfo":"IsRelease"::BOOLEAN) = TRUE
), Latest AS (
    SELECT "Name", "Version"
    FROM LatestRelease
    WHERE rn = 1
), PkgProjects AS (
    SELECT
        l."Name",
        l."Version",
        pvtp."ProjectName"
    FROM Latest l
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONTOPROJECT" pvtp
      ON l."Name" = pvtp."Name"
     AND l."Version" = pvtp."Version"
    WHERE pvtp."System" = 'NPM'
      AND pvtp."ProjectType" = 'GITHUB'
), PkgStars AS (
    SELECT
        pp."Name",
        pp."Version",
        MAX(pr."StarsCount") AS "StarsCount"
    FROM PkgProjects pp
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PROJECTS" pr
      ON pr."Name" = pp."ProjectName"
     AND pr."Type" = 'GITHUB'
    GROUP BY pp."Name", pp."Version"
)
SELECT
    "Name"      AS "Package",
    "Version",
    "StarsCount"
FROM PkgStars
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;