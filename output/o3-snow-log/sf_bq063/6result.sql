WITH latest_release AS (   -- latest released version (highest Ordinal) for every un-scoped NPM package
    SELECT
        pv."Name",
        pv."Version",
        (pv."VersionInfo":"Ordinal")::NUMBER     AS ordinal
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                               -- exclude names containing '@'
      AND COALESCE((pv."VersionInfo":"IsRelease")::BOOLEAN, FALSE) = TRUE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pv."Name"
                               ORDER BY (pv."VersionInfo":"Ordinal")::NUMBER DESC NULLS LAST,
                                        pv."Version"               DESC) = 1
),
dependency_counts AS (      -- how many direct dependencies each of those versions has
    SELECT
        lr."Name",
        lr."Version",
        COUNT(d."Dependency") AS dep_count
    FROM latest_release lr
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON d."System"  = 'NPM'
          AND d."Name"    = lr."Name"
          AND d."Version" = lr."Version"
    GROUP BY lr."Name", lr."Version"
),
most_deps AS (              -- the package version with the maximum number of dependencies
    SELECT *
    FROM dependency_counts
    QUALIFY ROW_NUMBER() OVER (ORDER BY dep_count DESC NULLS LAST) = 1
),
source_repo_links AS (      -- grab its Links array
    SELECT pv."Links"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    JOIN most_deps md
      ON pv."System"  = 'NPM'
     AND pv."Name"    = md."Name"
     AND pv."Version" = md."Version"
)
SELECT
    l.value:"URL"::STRING AS "GitHubSourceRepoURL"
FROM source_repo_links,
     LATERAL FLATTEN(INPUT => "Links") l
WHERE l.value:"Label"::STRING ILIKE 'SOURCE_REPO'   -- only SOURCE_REPO links
  AND l.value:"URL"::STRING  ILIKE '%github.com%'  -- and only GitHub URLs
QUALIFY ROW_NUMBER() OVER (ORDER BY 1) = 1;         -- return a single URL