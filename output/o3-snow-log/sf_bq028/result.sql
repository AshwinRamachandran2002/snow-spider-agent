WITH latest_release AS (
    /* 1. pick the newest *released* version for every NPM package */
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal"::NUMBER) DESC
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
        WHERE "System" = 'NPM'
          AND ("VersionInfo":"IsRelease"::BOOLEAN) = TRUE
    )
    WHERE rn = 1
),
latest_to_project AS (
    /* 2. map those latest versions to their GitHub repositories */
    SELECT
        lr."Name"        AS "PackageName",
        lr."Version",
        pv2p."ProjectName" AS "RepoFullName"
    FROM latest_release lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONTOPROJECT" pv2p
      ON lr."Name"    = pv2p."Name"
     AND lr."Version" = pv2p."Version"
    WHERE pv2p."ProjectType" = 'GITHUB'
),
stars_per_package AS (
    /* 3. attach GitHub star counts */
    SELECT
        ltp."PackageName",
        ltp."Version",
        pr."StarsCount"
    FROM latest_to_project ltp
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PROJECTS" pr
      ON pr."Name" = ltp."RepoFullName"
),
dedup AS (
    /* 4. some packages map to the same repo more than once; keep one row each */
    SELECT
        "PackageName",
        "Version",
        "StarsCount",
        ROW_NUMBER() OVER (
            PARTITION BY "PackageName"
            ORDER BY "StarsCount" DESC NULLS LAST
        ) AS rn
    FROM stars_per_package
)
SELECT
    "PackageName",
    "Version",
    "StarsCount"
FROM dedup
WHERE rn = 1                       -- one row per package
ORDER BY "StarsCount" DESC NULLS LAST
LIMIT 8;                            -- top-8 most-starred packages