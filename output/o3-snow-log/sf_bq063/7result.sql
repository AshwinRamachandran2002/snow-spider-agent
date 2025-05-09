WITH released_versions AS (   -- all *released* NPM versions whose package name has no '@'
    SELECT
        "Name",
        "Version",
        COALESCE(TO_NUMBER("VersionInfo":Ordinal), -1)               AS "Ord",
        "SnapshotAt"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "Name" NOT LIKE '%@%'                                       -- exclude scoped pkgs
      AND "VersionInfo":IsRelease::BOOLEAN = TRUE                     -- only releases
), latest_release_per_pkg AS (      -- keep latest release (highest Ordinal) per package
    SELECT
        *
    FROM (
        SELECT
            rv.*,
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "Ord" DESC NULLS LAST, "Version" DESC) AS rn
        FROM released_versions rv
    )
    WHERE rn = 1
), dep_counts AS (                 -- count dependencies for every latest-release version
    SELECT
        lr."Name",
        lr."Version",
        COUNT(*) AS "DepCnt"
    FROM latest_release_per_pkg lr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
      ON  d."System"  = 'NPM'
      AND d."Name"    = lr."Name"
      AND d."Version" = lr."Version"
    GROUP BY lr."Name", lr."Version"
), pkg_with_most_deps AS (         -- pick the package with the largest dependency count
    SELECT *
    FROM (
        SELECT
            dc.*,
            ROW_NUMBER() OVER (ORDER BY "DepCnt" DESC NULLS LAST, "Name") AS rn
        FROM dep_counts dc
    )
    WHERE rn = 1
), target_package_row AS (         -- the PACKAGEVERSIONS row for that package/version
    SELECT pv.*
    FROM pkg_with_most_deps p
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
      ON  pv."System"  = 'NPM'
      AND pv."Name"    = p."Name"
      AND pv."Version" = p."Version"
)
SELECT DISTINCT                        -- final answer: GitHub SOURCE_REPO URL
       f.value:"URL"::STRING AS "GitHub_Source_Repo_URL"
FROM target_package_row,
     LATERAL FLATTEN(INPUT => target_package_row."Links") f
WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
  AND f.value:"URL"::STRING ILIKE '%github.com%'
LIMIT 1;