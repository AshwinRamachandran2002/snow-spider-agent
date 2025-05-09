WITH latest_release AS (   -- 1. latest *release* version of every NPM package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE
            "System" = 'NPM'
            AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
pkg_repo AS (              -- 2. map those versions to their GitHub repos
    SELECT
        lr."Name"         AS "PackageName",
        lr."Version",
        pvtp."ProjectName"
    FROM latest_release lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pvtp
      ON  lr."Name"    = pvtp."Name"
      AND lr."Version" = pvtp."Version"
      AND pvtp."ProjectType"  = 'GITHUB'
      AND pvtp."RelationType" = 'SOURCE_REPO_TYPE'
),
pkg_stars AS (             -- 3. attach GitHub star counts
    SELECT
        pr."PackageName",
        pr."Version",
        proj."StarsCount",
        ROW_NUMBER() OVER (          -- keep repo with most stars if multiples
            PARTITION BY pr."PackageName"
            ORDER BY proj."StarsCount" DESC NULLS LAST
        ) AS star_rn
    FROM pkg_repo pr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS proj
      ON  proj."Type" = 'GITHUB'
      AND proj."Name" = pr."ProjectName"
)
-- 4. top-8 most-starred packages (latest release only)
SELECT
    "PackageName",
    "Version",
    "StarsCount"
FROM pkg_stars
WHERE star_rn = 1
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;