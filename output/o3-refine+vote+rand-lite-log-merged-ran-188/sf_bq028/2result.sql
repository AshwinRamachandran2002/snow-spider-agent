WITH latest_projects AS (      -- latest GitHub snapshot for each repo
    SELECT
        "Name",
        "StarsCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS
    WHERE "Type" = 'GITHUB'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "SnapshotAt" DESC) = 1
),
latest_pkg_release AS (       -- latest released version for each NPM package
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY COALESCE("VersionInfo":"Ordinal"::NUMBER,0) DESC,
                                        "UpstreamPublishedAt" DESC NULLS LAST) = 1
),
latest_pvtp AS (              -- latest mapping of package‑version to repo
    SELECT
        "Name",
        "Version",
        "ProjectName"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT
    WHERE "System" = 'NPM'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name","Version"
                               ORDER BY "SnapshotAt" DESC) = 1
)
SELECT
    lp."Name"     AS "PackageName",
    lp."Version",
    pr."StarsCount"
FROM latest_pkg_release lp
JOIN latest_pvtp   pv   ON pv."Name" = lp."Name"
                       AND pv."Version" = lp."Version"
JOIN latest_projects pr ON pr."Name" = pv."ProjectName"
ORDER BY pr."StarsCount" DESC NULLS LAST,
         lp."Name"
LIMIT 8;