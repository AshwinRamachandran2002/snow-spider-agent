WITH latest_release AS (            -- newest *release* version of every NPM package
    SELECT
        pv."Name",
        pv."Version",
        ROW_NUMBER() OVER (
              PARTITION BY pv."Name"
              ORDER BY (PARSE_JSON(pv."VersionInfo"):"Ordinal"::NUMBER) DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND PARSE_JSON(pv."VersionInfo"):"IsRelease"::BOOLEAN = TRUE
),
latest_pkg AS (                     -- keep only the newest release row
    SELECT "Name", "Version"
    FROM   latest_release
    WHERE  rn = 1
),
pkg_to_repo AS (                    -- link package version to its GitHub repository
    SELECT
        lp."Name",
        lp."Version",
        pvt."ProjectName"
    FROM   latest_pkg lp
    JOIN   DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONTOPROJECT" pvt
           ON  pvt."System"        = 'NPM'
           AND pvt."Name"          = lp."Name"
           AND pvt."Version"       = lp."Version"
           AND pvt."ProjectType"   = 'GITHUB'
           AND pvt."RelationType"  = 'SOURCE_REPO_TYPE'
),
pkg_with_stars AS (                 -- attach GitHub star counts
    SELECT
        ptr."Name"        AS "Package",
        ptr."Version",
        proj."StarsCount"
    FROM   pkg_to_repo ptr
    JOIN   DEPS_DEV_V1.DEPS_DEV_V1."PROJECTS" proj
           ON  proj."Type" = 'GITHUB'
           AND proj."Name" = ptr."ProjectName"
)
SELECT
    "Package",
    "Version",
    "StarsCount"
FROM   pkg_with_stars
ORDER  BY "StarsCount" DESC NULLS LAST
LIMIT  8;