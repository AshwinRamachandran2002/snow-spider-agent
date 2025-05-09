WITH release_versions AS (          -- all release versions of NPM packages
    SELECT
        "Name",
        "Version",
        "VersionInfo":"Ordinal"::NUMBER AS "Ordinal",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),                                 -- keep only the latest release per package
latest_releases AS (
    SELECT "Name", "Version"
    FROM release_versions
    WHERE rn = 1
),                                 -- map those releases to their GitHub repos
package_repo AS (
    SELECT
        lr."Name"        AS "PackageName",
        lr."Version"     AS "LatestVersion",
        p2p."ProjectName" AS "GitHubRepo"
    FROM latest_releases lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONTOPROJECT" p2p
      ON lr."Name" = p2p."Name"
     AND lr."Version" = p2p."Version"
    WHERE p2p."ProjectType"  = 'GITHUB'
      AND p2p."RelationType" = 'SOURCE_REPO_TYPE'
),                                 -- pick the most-recent star count per repo
repo_stars AS (
    SELECT
        pr."Name"       AS "GitHubRepo",
        pr."StarsCount",
        ROW_NUMBER() OVER (
            PARTITION BY pr."Name"
            ORDER BY pr."SnapshotAt" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PROJECTS" pr
    WHERE pr."Type" = 'GITHUB'
)
SELECT
    pr."PackageName",
    pr."LatestVersion",
    rs."StarsCount"
FROM package_repo pr
JOIN repo_stars rs
  ON pr."GitHubRepo" = rs."GitHubRepo"
WHERE rs.rn = 1                     -- latest snapshot for each repo
ORDER BY rs."StarsCount" DESC NULLS LAST
LIMIT 8;                            -- top 8 most-starred packages