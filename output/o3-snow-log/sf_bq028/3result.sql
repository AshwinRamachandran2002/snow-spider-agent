WITH latest_release AS (
    /* 1.  Latest *release* version for every NPM package that maps to a GitHub repo */
    SELECT
        pv."Name",
        pv."Version",
        pv."VersionInfo":"Ordinal"::NUMBER             AS "Ordinal",
        pvtp."ProjectName",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST
        )                                             AS "rn"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"         pv
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvtp
         ON  pv."System"  = 'NPM'
         AND pvtp."System"= 'NPM'
         AND pv."Name"    = pvtp."Name"
         AND pv."Version" = pvtp."Version"
    WHERE pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
project_stars AS (
    /* 2.  For every GitHub project keep its highest recorded star count */
    SELECT
        pr."Name"                       AS "ProjectName",
        MAX(pr."StarsCount")            AS "StarsCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pr
    WHERE pr."Type" = 'GITHUB'
    GROUP BY pr."Name"
),
ranked AS (
    /* 3.  Attach star counts to the latest package releases */
    SELECT
        lr."Name"                     AS "Package",
        lr."Version"                  AS "Version",
        ps."StarsCount"
    FROM latest_release lr
    JOIN project_stars  ps
         ON ps."ProjectName" = lr."ProjectName"
    WHERE lr."rn" = 1               -- keep only latest release per package
)
SELECT
    "Package",
    "Version",
    "StarsCount"
FROM ranked
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;