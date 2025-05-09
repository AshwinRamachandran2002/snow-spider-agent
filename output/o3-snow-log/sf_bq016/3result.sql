WITH highest_release AS (
    /* pick the highest released version for every NPM package */
    SELECT  "Name",
            "Version"
    FROM   (
        SELECT  "Name",
                "Version",
                ROW_NUMBER() OVER (PARTITION BY "Name"
                                   ORDER BY COALESCE(("VersionInfo":"Ordinal")::NUMBER,0) DESC) AS rn
        FROM   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE  "System" = 'NPM'
          AND  ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE  rn = 1
),
all_deps AS (
    /* dependencies of those highest-release package versions */
    SELECT  PARSE_JSON("Dependency"):"Name"::STRING   AS dep_name,
            PARSE_JSON("Dependency"):"Version"::STRING AS dep_version
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN   highest_release hr
           ON  d."System"  = 'NPM'
           AND d."Name"    = hr."Name"
           AND d."Version" = hr."Version"
)
SELECT  dep_name      AS "DependencyPackage",
        dep_version   AS "DependencyVersion",
        COUNT(*)      AS "Appearances"
FROM    all_deps
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC NULLS LAST
LIMIT 1;