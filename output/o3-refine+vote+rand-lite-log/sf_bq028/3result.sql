WITH latest_release AS (
    SELECT
        "Name",
        "Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND COALESCE((PARSE_JSON("VersionInfo"):"IsRelease")::BOOLEAN, FALSE)
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY COALESCE((PARSE_JSON("VersionInfo"):"Ordinal")::NUMBER, 0) DESC,
                         "Version" DESC
            ) = 1
),
package_repo AS (
    SELECT
        lr."Name",
        lr."Version",
        pvtp."ProjectName"
    FROM latest_release lr
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvtp
      ON lr."Name" = pvtp."Name"
     AND lr."Version" = pvtp."Version"
     AND pvtp."System" = 'NPM'
     AND pvtp."ProjectType" = 'GITHUB'
     AND pvtp."RelationType" = 'SOURCE_REPO_TYPE'
),
latest_project_metrics AS (
    SELECT
        "Name" AS "ProjectName",
        "StarsCount"
    FROM (
        SELECT
            "Name",
            "StarsCount",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "SnapshotAt" DESC) AS rn
        FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS"
        WHERE "Type" = 'GITHUB'
    )
    WHERE rn = 1
)
SELECT
    prq."Name"    AS "PackageName",
    prq."Version",
    lpm."StarsCount"
FROM package_repo prq
JOIN latest_project_metrics lpm
  ON prq."ProjectName" = lpm."ProjectName"
ORDER BY lpm."StarsCount" DESC NULLS LAST,
         "PackageName"
LIMIT 8;