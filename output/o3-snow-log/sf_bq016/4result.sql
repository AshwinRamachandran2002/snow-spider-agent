WITH latest_releases AS (
    /* pick the highest (largest Ordinal) released version for every NPM package */
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "VersionInfo":"Ordinal"::NUMBER                AS ord,
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST
            )                                             AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND COALESCE("VersionInfo":"IsRelease"::BOOLEAN, FALSE)
    )
    WHERE rn = 1
),

selected_dependencies AS (
    /* dependencies coming from only those highest-release package versions */
    SELECT
        "Dependency":"Name"::TEXT    AS dep_name,
        "Dependency":"Version"::TEXT AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN latest_releases lr
      ON d."System"  = 'NPM'
     AND d."Name"    = lr."Name"
     AND d."Version" = lr."Version"
)

SELECT
    dep_name         AS "DependencyName",
    dep_version      AS "DependencyVersion",
    COUNT(*)         AS "Frequency"
FROM selected_dependencies
GROUP BY dep_name, dep_version
ORDER BY "Frequency" DESC NULLS LAST
LIMIT 1;