WITH npm_releases AS (
    SELECT
        "Name",
        "Version",
        "VersionInfo":"Ordinal"::NUMBER                         AS "Ordinal",
        ROW_NUMBER() OVER (PARTITION BY "Name"
                           ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC) AS rn
    FROM   "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE  "System" = 'NPM'
      AND  "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
highest_release AS (
    SELECT  "Name", "Version"
    FROM    npm_releases
    WHERE   rn = 1
),
deps_of_highest AS (
    SELECT
        d."Dependency":"Name"::STRING    AS dep_name,
        d."Dependency":"Version"::STRING AS dep_version
    FROM   "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    JOIN   highest_release h
           ON  h."Name"    = d."Name"
           AND h."Version" = d."Version"
    WHERE  d."System" = 'NPM'
)
SELECT
    dep_name      AS "DependencyName",
    dep_version   AS "DependencyVersion",
    COUNT(*)      AS "Appearances"
FROM   deps_of_highest
GROUP  BY dep_name, dep_version
ORDER  BY "Appearances" DESC, dep_name, dep_version
LIMIT 1;