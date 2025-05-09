WITH latest_release AS (
    /* Latest *release* version for every NPM package */
    SELECT
        pv."Name",
        pv."Version",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY (pv."VersionInfo":"Ordinal"::NUMBER) DESC
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE) = TRUE
), latest_pkgs AS (
    /* Keep only the latest release per package */
    SELECT
        "Name",
        "Version"
    FROM latest_release
    WHERE rn = 1
), pkg_to_repo AS (
    /* Map those package versions to their GitHub repositories */
    SELECT
        lp."Name"        AS "PackageName",
        lp."Version",
        pvtp."ProjectName"
    FROM latest_pkgs lp
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvtp
      ON pvtp."System"      = 'NPM'
     AND pvtp."Name"        = lp."Name"
     AND pvtp."Version"     = lp."Version"
     AND pvtp."ProjectType" = 'GITHUB'
), pkg_with_stars AS (
    /* Attach GitHub star counts */
    SELECT
        ptr."PackageName",
        ptr."Version" AS "LatestReleaseVersion",
        pr."StarsCount"
    FROM pkg_to_repo ptr
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pr
      ON pr."Type" = 'GITHUB'
     AND pr."Name" = ptr."ProjectName"
)
SELECT
    "PackageName",
    "LatestReleaseVersion",
    "StarsCount"
FROM pkg_with_stars
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY "PackageName"
            ORDER BY "StarsCount" DESC
        ) = 1
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;