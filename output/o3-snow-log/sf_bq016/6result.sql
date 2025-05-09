WITH highest_versions AS (   -- 1. one highest *release* version per NPM package
    SELECT  "Name",
            "Version"
    FROM (
        SELECT  "Name",
                "Version",
                ("VersionInfo":"Ordinal")::NUMBER                         AS ord,
                ROW_NUMBER() OVER (PARTITION BY "Name"
                                   ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC) AS rn
        FROM    DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE   "System" = 'NPM'
          AND   ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
deps AS (                     -- 2. dependencies of those highest-version packages
    SELECT  PARSE_JSON(d."Dependency") AS dep_json
    FROM    DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN    highest_versions hv
           ON d."System"  = 'NPM'
          AND d."Name"    = hv."Name"
          AND d."Version" = hv."Version"
    WHERE   d."Dependency" IS NOT NULL
)
-- 3. dependency (package + version) appearing most often
SELECT  deps.dep_json:"Name"::STRING    AS "Dependency_Name",
        deps.dep_json:"Version"::STRING AS "Dependency_Version",
        COUNT(*)                       AS "Frequency"
FROM    deps
GROUP BY  deps.dep_json:"Name"::STRING,
          deps.dep_json:"Version"::STRING
ORDER BY  "Frequency" DESC NULLS LAST
LIMIT 1;