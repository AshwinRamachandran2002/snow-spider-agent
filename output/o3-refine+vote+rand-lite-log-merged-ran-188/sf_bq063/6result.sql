WITH latest_released AS (
    /* latest released version (IsRelease = true) for every NPM package 
       whose name DOES NOT contain '@'                                        */
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        COALESCE(pv."UpstreamPublishedAt", 0) AS published_at,
        pv."SnapshotAt",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY COALESCE(pv."UpstreamPublishedAt", 0) DESC,
                     pv."SnapshotAt"                 DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
latest_per_pkg AS (
    SELECT *
    FROM latest_released
    WHERE rn = 1          -- keep only the latest released version per package
),
dependency_counts AS (
    /* how many dependencies each (Name, Version) pair has */
    SELECT
        d."Name",
        d."Version",
        COUNT(DISTINCT d."Dependency") AS dep_cnt
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
candidates AS (
    /* join latest versions with their dependency counts */
    SELECT
        lp."Name",
        lp."Version",
        lp."Links",
        COALESCE(dc.dep_cnt, 0) AS dep_cnt
    FROM latest_per_pkg lp
    LEFT JOIN dependency_counts dc
           ON lp."Name" = dc."Name"
          AND lp."Version" = dc."Version"
),
github_links AS (
    /* explode Links array, keep only SOURCE_REPO entries that point to GitHub */
    SELECT
        c."Name",
        c."Version",
        c.dep_cnt,
        f.value:"URL"::TEXT AS github_url
    FROM candidates c,
         LATERAL FLATTEN(input => c."Links") f
    WHERE f.value:"Label"::TEXT = 'SOURCE_REPO'
      AND f.value:"URL"::TEXT ILIKE '%github.com%'
),
ranked AS (
    /* pick the package whose latest released version has the most dependencies */
    SELECT
        g.github_url,
        ROW_NUMBER() OVER (ORDER BY g.dep_cnt DESC, g."Name" ASC, g.github_url ASC) AS rnk
    FROM github_links g
)
SELECT github_url
FROM ranked
WHERE rnk = 1
LIMIT 1;