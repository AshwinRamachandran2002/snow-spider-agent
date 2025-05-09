WITH latest_release AS (
    SELECT
        "Name",
        "Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY "Name"
              ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
           ) = 1
), pkg_repo AS (
    SELECT
        "Name"        AS "PackageName",
        "Version"     AS "PackageVersion",
        "ProjectName" AS "GitHubProject"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT"
    WHERE "System"       = 'NPM'
      AND "RelationType" = 'SOURCE_REPO_TYPE'
      AND "ProjectType"  = 'GITHUB'
)
SELECT
    lr."Name"      AS "PackageName",
    lr."Version"   AS "Version",
    pj."StarsCount"
FROM latest_release lr
JOIN pkg_repo pr
  ON lr."Name"    = pr."PackageName"
 AND lr."Version" = pr."PackageVersion"
JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pj
  ON pj."Name" = pr."GitHubProject"
WHERE pj."StarsCount" IS NOT NULL
ORDER BY pj."StarsCount" DESC NULLS LAST
LIMIT 8;