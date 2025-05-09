WITH highest_releases AS (          -- highest *release* version of every NPM package
    SELECT  "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC          -- newest first
            ) AS rn
    FROM    DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE   "System" = 'NPM'
      AND   "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
latest_pkgs AS (                    -- keep only the single newest release per package
    SELECT "Name", "Version"
    FROM   highest_releases
    WHERE  rn = 1
),
deps AS (                            -- distinct dependencies of those newest releases
    SELECT DISTINCT
           lp."Name"                       AS pkg_name,
           lp."Version"                    AS pkg_version,
           d."Dependency":"Name"::STRING   AS dep_name,
           d."Dependency":"Version"::STRING AS dep_version,
           d."Dependency":"System"::STRING AS dep_system
    FROM   latest_pkgs                     lp
    JOIN   DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON lp."Name"    = d."Name"
          AND lp."Version" = d."Version"
          AND d."System"   = 'NPM'
)
SELECT  dep_name,
        dep_version,
        COUNT(*) AS appearances
FROM    deps
WHERE   dep_system = 'NPM'                 -- keep only NPM-to-NPM edges
GROUP BY dep_name, dep_version
ORDER BY appearances DESC NULLS LAST
LIMIT 1;