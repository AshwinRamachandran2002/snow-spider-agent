WITH released AS (                               -- released NPM versions whose names lack '@'
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
latest AS (                                      -- latest release per package
    SELECT
        r."Name",
        MAX(r."SnapshotAt") AS "LatestSnapshot"
    FROM released r
    GROUP BY r."Name"
),
latest_pkgs AS (                                 -- (package,version) pairs for latest releases
    SELECT
        r."Name",
        r."Version"
    FROM released r
    JOIN latest l
      ON r."Name"       = l."Name"
     AND r."SnapshotAt" = l."LatestSnapshot"
),
with_github AS (                                 -- keep those with a GitHub SOURCE_REPO link
    SELECT
        lp."Name",
        lp."Version",
        l.value:"URL"::STRING AS "GitHubURL"
    FROM latest_pkgs lp
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
      ON pv."System"  = 'NPM'
     AND pv."Name"    = lp."Name"
     AND pv."Version" = lp."Version",
    LATERAL FLATTEN(input => pv."Links") l
    WHERE l.value:"Label"::STRING = 'SOURCE_REPO'
      AND l.value:"URL"::STRING ILIKE '%github.com%'
),
dep_counts AS (                                  -- dependency counts for those versions
    SELECT
        wg."Name",
        wg."Version",
        wg."GitHubURL",
        COUNT(d."Dependency") AS "DepsCount"
    FROM with_github wg
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
           ON d."System"  = 'NPM'
          AND d."Name"    = wg."Name"
          AND d."Version" = wg."Version"
    GROUP BY wg."Name", wg."Version", wg."GitHubURL"
)
SELECT                                            -- final result
    "Name",
    "Version",
    "GitHubURL"
FROM dep_counts
ORDER BY "DepsCount" DESC NULLS LAST
LIMIT 1;