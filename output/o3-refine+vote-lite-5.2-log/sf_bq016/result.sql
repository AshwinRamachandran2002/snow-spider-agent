WITH release_versions AS (
    SELECT
        "Name",
        "Version",
        ("VersionInfo":"Ordinal")::NUMBER           AS ordinal
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
), latest_release AS (
    SELECT
        "Name"   AS pkg_name,
        "Version" AS pkg_version
    FROM (
        SELECT
            "Name",
            "Version",
            ordinal,
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY ordinal DESC NULLS LAST,
                                        "Version" DESC) AS rn
        FROM release_versions
    )
    WHERE rn = 1
), deps AS (
    SELECT
        d."Dependency":"Name"::TEXT    AS dep_name,
        d."Dependency":"Version"::TEXT AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN latest_release lr
      ON d."System"  = 'NPM'
     AND d."Name"    = lr.pkg_name
     AND d."Version" = lr.pkg_version
)
SELECT
    dep_name  AS "DEPENDENCY_NAME",
    dep_version AS "DEPENDENCY_VERSION",
    COUNT(*)   AS "OCCURRENCES"
FROM deps
GROUP BY dep_name, dep_version
ORDER BY "OCCURRENCES" DESC NULLS LAST,
         dep_name,
         dep_version
LIMIT 1;