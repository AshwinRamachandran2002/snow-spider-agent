WITH highest_release AS (   -- highest released version of every NPM package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "VersionInfo":"Ordinal"::NUMBER          AS ord,
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ord DESC                   -- highest ordinal ⇒ latest release
            )                                       AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
        WHERE "System" = 'NPM'
          AND "VersionInfo":"IsRelease"::BOOLEAN
    )
    WHERE rn = 1
),

deps AS (            -- dependencies of those highest-release packages
    SELECT
        d."Dependency":"Name"::STRING     AS dep_name,
        d."Dependency":"Version"::STRING  AS dep_version,
        d."Name"                          AS pkg_name          -- package that has the dependency
    FROM DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES"  d
    JOIN highest_release                     hr
      ON hr."Name"    = d."Name"
     AND hr."Version" = d."Version"
     AND d."System"   = 'NPM'               -- only dependencies belonging to NPM packages
    WHERE d."Dependency":"Name" IS NOT NULL
)

SELECT
    dep_name        AS "DependencyPackage",
    dep_version     AS "DependencyVersion",
    COUNT(DISTINCT pkg_name) AS "Frequency"
FROM deps
GROUP BY dep_name, dep_version
ORDER BY "Frequency" DESC NULLS LAST
LIMIT 1;