/* Top 8 most-starred GitHub projects for the latest release
   version of every NPM package */
WITH latest_release AS (          -- one latest *release* version per NPM package
    SELECT  "Name",
            "Version"
    FROM   (
        SELECT  "Name",
                "Version",
                "VersionInfo":"Ordinal"::NUMBER                        AS ord,
                ROW_NUMBER() OVER (PARTITION BY "Name"
                                   ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC) AS rn
        FROM    DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE   "System" = 'NPM'
          AND   "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
pkg_to_project AS (               -- map the latest version to its GitHub project & stars
    SELECT  lr."Name",
            lr."Version",
            pr."StarsCount"
    FROM   latest_release            lr
    JOIN   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT  map
           ON  lr."Name"    = map."Name"
           AND lr."Version" = map."Version"
           AND map."System" = 'NPM'
    JOIN   DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS                 pr
           ON  pr."Name" = map."ProjectName"
           AND pr."Type" = 'GITHUB'
),
dedup AS (                        -- if multiple projects map to same package, keep highest stars
    SELECT  "Name",
            "Version",
            "StarsCount",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "StarsCount" DESC) AS rn
    FROM    pkg_to_project
)
SELECT  "Name",
        "Version",
        "StarsCount"
FROM    dedup
WHERE   rn = 1
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;