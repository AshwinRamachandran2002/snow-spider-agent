WITH latest_releases AS (   -- highest released version for every NPM package
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND COALESCE(("VersionInfo":"IsRelease")::BOOLEAN, FALSE) = TRUE
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY COALESCE(("VersionInfo":"Ordinal")::NUMBER, 0) DESC
            ) = 1
),
dependencies_of_latest AS ( -- dependencies of those highest‑release versions
    SELECT
        (d."Dependency":"Name")::TEXT    AS dep_name,
        (d."Dependency":"Version")::TEXT AS dep_version
    FROM latest_releases lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System" = 'NPM'
     AND d."Name"   = lr."Name"
     AND d."Version"= lr."Version"
)
SELECT
    dep_name       AS "DependencyName",
    dep_version    AS "DependencyVersion",
    COUNT(*)       AS "Frequency"
FROM dependencies_of_latest
GROUP BY dep_name, dep_version
ORDER BY "Frequency" DESC NULLS LAST, "DependencyName", "DependencyVersion"
LIMIT 1;