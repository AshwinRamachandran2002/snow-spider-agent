WITH npm_release_versions AS (      -- keep only release versions of NPM packages
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        pv."VersionInfo":"Ordinal"::NUMBER                              AS ordinal,
        ROW_NUMBER() OVER (PARTITION BY pv."Name"
                           ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST,
                                    pv."SnapshotAt" DESC)              AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE)
),
latest_npm_release AS (             -- latest release per package
    SELECT "Name", "Version"
    FROM   npm_release_versions
    WHERE  rn = 1
),
latest_projects AS (                -- latest snapshot per project to get star count
    SELECT
        pr."Type",
        pr."Name",
        pr."StarsCount"
    FROM (
        SELECT
            pr.*,
            ROW_NUMBER() OVER (PARTITION BY pr."Type", pr."Name"
                               ORDER BY pr."SnapshotAt" DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS pr
    ) pr
    WHERE rn = 1
),
pkg_to_proj AS (                    -- latest mapping of package‑version to GitHub project
    SELECT
        p2p."System",
        p2p."Name",
        p2p."Version",
        p2p."ProjectType",
        p2p."ProjectName"
    FROM (
        SELECT
            p2p.*,
            ROW_NUMBER() OVER (PARTITION BY p2p."System", p2p."Name", p2p."Version",
                                           p2p."ProjectType", p2p."ProjectName"
                               ORDER BY p2p."SnapshotAt" DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT p2p
        WHERE p2p."System" = 'NPM'
    ) p2p
    WHERE rn = 1
),
joined AS (                         -- combine everything
    SELECT
        ln."Name"    AS package_name,
        ln."Version" AS version,
        lp."StarsCount"
    FROM latest_npm_release ln
    JOIN pkg_to_proj p2p
      ON p2p."Name"    = ln."Name"
     AND p2p."Version" = ln."Version"
    JOIN latest_projects lp
      ON lp."Type" = p2p."ProjectType"
     AND lp."Name" = p2p."ProjectName"
)
SELECT
    package_name   AS "PackageName",
    version        AS "Version",
    MAX("StarsCount") AS "StarsCount"
FROM joined
GROUP BY package_name, version
ORDER BY "StarsCount" DESC NULLS LAST, package_name
LIMIT 8;