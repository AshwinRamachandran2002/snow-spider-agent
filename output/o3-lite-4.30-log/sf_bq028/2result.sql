WITH latest_release AS (          -- latest official NPM release per package
    SELECT
        "Name",
        "Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
      AND POSITION('>' IN "Name") = 0        -- exclude synthetic names
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY "Name"
        ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
    ) = 1
),
package_project AS (              -- most‑recent mapping from package → GitHub repo
    SELECT
        "Name",
        "ProjectName"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT"
    WHERE "System" = 'NPM'
      AND "ProjectType" = 'GITHUB'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY "Name"
        ORDER BY "SnapshotAt" DESC
    ) = 1
),
latest_project AS (               -- freshest GitHub snapshot → star count
    SELECT
        "Name"        AS "ProjectName",
        "StarsCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS"
    WHERE "Type" = 'GITHUB'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY "Name"
        ORDER BY "SnapshotAt" DESC
    ) = 1
)
SELECT
    lr."Name"        AS package_name,
    lr."Version"     AS latest_version,
    lp."StarsCount"  AS github_stars
FROM       latest_release  lr
INNER JOIN package_project pp  ON pp."Name"        = lr."Name"
INNER JOIN latest_project  lp  ON lp."ProjectName" = pp."ProjectName"
WHERE lp."StarsCount" IS NOT NULL
QUALIFY ROW_NUMBER() OVER (       -- ensure one row per package
    PARTITION BY package_name
    ORDER BY github_stars DESC
) = 1
ORDER BY github_stars DESC NULLS LAST, package_name
LIMIT 8;