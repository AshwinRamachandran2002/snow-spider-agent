WITH latest_releases AS (               -- newest *released* version for every NPM package (excluding “@”)
    SELECT
        p."Name",
        p."Version",
        p."SnapshotAt"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" p
    WHERE p."System" = 'NPM'
      AND p."Name" NOT ILIKE '%@%'
      AND p."VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (            -- keep newest by Ordinal then SnapshotAt
              PARTITION BY p."Name"
              ORDER BY p."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST,
                       p."SnapshotAt"              DESC NULLS LAST
            ) = 1
),
dependency_counts AS (                   -- count dependencies for those newest versions
    SELECT
        lr."Name",
        lr."Version",
        COUNT(d."Dependency") AS "DepsCount"
    FROM latest_releases lr
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON d."System"  = 'NPM'
          AND d."Name"    = lr."Name"
          AND d."Version" = lr."Version"
    GROUP BY lr."Name", lr."Version"
),
top_pkg AS (                             -- package whose newest release has the most dependencies
    SELECT "Name", "Version"
    FROM dependency_counts
    ORDER BY "DepsCount" DESC NULLS LAST
    LIMIT 1
)
SELECT
    l.value:"URL"::STRING AS "GitHub_SourceRepo_URL"
FROM top_pkg tp
JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" p
  ON p."Name"    = tp."Name"
 AND p."Version" = tp."Version",
LATERAL FLATTEN(input => p."Links") l
WHERE l.value:"Label"::STRING = 'SOURCE_REPO'
  AND l.value:"URL"::STRING ILIKE '%github.com%'
LIMIT 1;