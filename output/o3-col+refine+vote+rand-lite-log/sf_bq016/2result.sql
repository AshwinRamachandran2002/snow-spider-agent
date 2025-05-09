/* 1)  Get, for every NPM package, its highest-release version            */
WITH highest_release AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal"::NUMBER) DESC NULLS LAST
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    )
    WHERE rn = 1
),

/* 2)  Collect dependencies of those highest-release versions             */
deps_of_highest AS (
    SELECT
        d."Dependency":"Name"::STRING    AS dep_name,
        d."Dependency":"Version"::STRING AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN highest_release hr
      ON d."System"  = 'NPM'
     AND d."Name"    = hr."Name"
     AND d."Version" = hr."Version"
)

/* 3)  Find the (dependency-package, dependency-version) occurring most   */
SELECT
    dep_name   AS "Dependency_Name",
    dep_version AS "Dependency_Version",
    COUNT(*)   AS "Appearances"
FROM deps_of_highest
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC NULLS LAST
LIMIT 1;