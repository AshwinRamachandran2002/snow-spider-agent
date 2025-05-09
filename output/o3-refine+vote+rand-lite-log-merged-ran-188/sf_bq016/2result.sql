WITH releases AS (
    SELECT
        "Name",
        "Version",
        (PARSE_JSON("VersionInfo"):"Ordinal")::NUMBER                AS ord,
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY (PARSE_JSON("VersionInfo"):"Ordinal")::NUMBER DESC
        )                                                           AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND (PARSE_JSON("VersionInfo"):"IsRelease")::BOOLEAN
),
top_releases AS (
    SELECT "Name", "Version"
    FROM releases
    WHERE rn = 1
),
release_deps AS (
    /* one row per (top‑release package, dependency) pair                */
    SELECT DISTINCT
        d."Name"                                                     AS pkg_name,
        (PARSE_JSON(d."Dependency"):"Name")::TEXT                    AS dep_name,
        (PARSE_JSON(d."Dependency"):"Version")::TEXT                 AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN top_releases tr
      ON d."System"  = 'NPM'
     AND d."Name"    = tr."Name"
     AND d."Version" = tr."Version"
)
SELECT
    dep_name      AS "DependencyPackage",
    dep_version   AS "DependencyVersion",
    COUNT(*)      AS "Appearances"
FROM release_deps
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC NULLS LAST, "DependencyPackage"
LIMIT 1;