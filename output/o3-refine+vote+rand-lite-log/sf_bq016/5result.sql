WITH latest_release AS (
    SELECT
        pv."Name"          AS pkg_name,
        pv."Version"       AS pkg_version,
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY
                COALESCE( (pv."VersionInfo":"Ordinal")::NUMBER , -1 ) DESC,
                pv."SnapshotAt" DESC
        )                  AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE
        pv."System" = 'NPM'
        AND COALESCE( (pv."VersionInfo":"IsRelease")::BOOLEAN , FALSE ) = TRUE
),

deps_of_latest AS (
    SELECT
        d."Dependency":"Name"::STRING    AS dep_name,
        d."Dependency":"Version"::STRING AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN latest_release lr
      ON  lr.rn = 1
      AND lr.pkg_name   = d."Name"
      AND lr.pkg_version = d."Version"
      AND d."System"    = 'NPM'
)

SELECT
    dep_name      AS "DependencyPackage",
    dep_version   AS "DependencyVersion",
    COUNT(*)      AS "Appearances"
FROM deps_of_latest
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC NULLS LAST, dep_name, dep_version
LIMIT 1;