WITH npm_release_versions AS (
    SELECT
        "Name",
        "Version",
        ("VersionInfo":"Ordinal")::INT AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND COALESCE(("VersionInfo":"IsRelease")::BOOLEAN, FALSE) = TRUE
),
highest_release_per_package AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Ordinal" DESC) AS rn
        FROM npm_release_versions
    )
    WHERE rn = 1
),
dependencies_of_highest AS (
    SELECT
        (d."Dependency":"Name")::STRING   AS dep_name,
        (d."Dependency":"Version")::STRING AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN highest_release_per_package hv
      ON d."System"  = 'NPM'
     AND d."Name"    = hv."Name"
     AND d."Version" = hv."Version"
)
SELECT
    dep_name      AS "DependencyPackage",
    dep_version   AS "DependencyVersion",
    COUNT(*)      AS "Appearances"
FROM dependencies_of_highest
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC, dep_name, dep_version
LIMIT 1;