WITH latest_release AS (
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        pv."UpstreamPublishedAt",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."UpstreamPublishedAt" DESC NULLS LAST, pv."SnapshotAt" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE)
), current_pkg_ver AS (
    SELECT
        "Name",
        "Version"
    FROM latest_release
    WHERE rn = 1
), pkg_repo AS (
    SELECT DISTINCT
        cpv."Name"                                                   AS pkg_name,
        cpv."Version",
        pvtp."ProjectName"
    FROM current_pkg_ver cpv
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pvtp
      ON pvtp."System"      = 'NPM'
     AND pvtp."Name"        = cpv."Name"
     AND pvtp."Version"     = cpv."Version"
     AND pvtp."ProjectType" = 'GITHUB'
), project_latest AS (
    SELECT
        pr."Name"                              AS project_full_name,
        pr."StarsCount",
        ROW_NUMBER() OVER (
            PARTITION BY pr."Name"
            ORDER BY pr."SnapshotAt" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS pr
    WHERE pr."Type" = 'GITHUB'
), projects AS (
    SELECT project_full_name, "StarsCount"
    FROM project_latest
    WHERE rn = 1
), combined AS (
    SELECT
        pp.pkg_name          AS "PackageName",
        pp."Version"         AS "Version",
        pr."StarsCount"
    FROM pkg_repo pp
    JOIN projects pr
      ON pr.project_full_name = pp."ProjectName"
)
SELECT
    "PackageName",
    "Version",
    "StarsCount"
FROM combined
ORDER BY "StarsCount" DESC NULLS LAST, "PackageName"
LIMIT 8;