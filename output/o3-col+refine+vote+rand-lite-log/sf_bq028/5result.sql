WITH latest_release AS (
    SELECT
        pv."Name",
        pv."Version",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY 
                (pv."VersionInfo":"Ordinal")::NUMBER DESC NULLS LAST,
                pv."SnapshotAt"                     DESC
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND (pv."VersionInfo":"IsRelease"::BOOLEAN IS NULL
           OR pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE)
),
latest AS (
    SELECT
        "Name",
        "Version"
    FROM latest_release
    WHERE rn = 1
),
stars AS (
    SELECT
        pvtp."Name",
        MAX(pj."StarsCount") AS "Stars"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvtp
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pj
         ON pj."Type" = 'GITHUB'
        AND pj."Name" = pvtp."ProjectName"
    WHERE pvtp."System"      = 'NPM'
      AND pvtp."ProjectType" = 'GITHUB'
      AND pvtp."RelationType" = 'SOURCE_REPO_TYPE'
    GROUP BY pvtp."Name"
)
SELECT
    l."Name",
    l."Version",
    s."Stars" AS "GitHubStars"
FROM latest l
JOIN stars  s
  ON s."Name" = l."Name"
ORDER BY s."Stars" DESC NULLS LAST
LIMIT 8;