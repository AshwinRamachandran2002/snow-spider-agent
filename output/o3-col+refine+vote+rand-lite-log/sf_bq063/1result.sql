WITH released_versions AS (          -- all un-scoped, released NPM versions
    SELECT
        p."Name",
        p."Version",
        p."SnapshotAt"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" p
    WHERE p."System" = 'NPM'
      AND p."Name" NOT LIKE '%@%'
      AND COALESCE(PARSE_JSON(p."VersionInfo"):"IsRelease"::BOOLEAN, FALSE) = TRUE
),
latest_per_pkg AS (                  -- latest released version per package
    SELECT
        rv."Name",
        rv."Version",
        ROW_NUMBER() OVER (PARTITION BY rv."Name"
                           ORDER BY rv."SnapshotAt" DESC) AS rn
    FROM released_versions rv
),
latest AS (                          -- keep only the latest version of each package
    SELECT "Name", "Version"
    FROM latest_per_pkg
    WHERE rn = 1
),
deps_cnt AS (                        -- dependency count for each latest version
    SELECT
        l."Name",
        l."Version",
        COUNT(d."Dependency") AS "DepsCount"
    FROM latest l
    LEFT JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
           ON d."System"  = 'NPM'
          AND d."Name"    = l."Name"
          AND d."Version" = l."Version"
    GROUP BY l."Name", l."Version"
),
links AS (                            -- GitHub SOURCE_REPO URLs
    SELECT
        p."Name",
        p."Version",
        f.value:"URL"::STRING AS "GitHubURL"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" p,
         LATERAL FLATTEN(input => PARSE_JSON(p."Links")) f
    WHERE p."System" = 'NPM'
      AND p."Name" NOT LIKE '%@%'
      AND f.value:"Label"::STRING = 'SOURCE_REPO'
      AND LOWER(f.value:"URL"::STRING) LIKE '%github.com%'
),
candidates AS (                       -- latest versions that have a GitHub SOURCE_REPO
    SELECT
        d."Name",
        d."Version",
        d."DepsCount",
        l."GitHubURL"
    FROM deps_cnt d
    JOIN links l
      ON l."Name"    = d."Name"
     AND l."Version" = d."Version"
)
SELECT "GitHubURL"
FROM (
    SELECT
        "GitHubURL",
        "DepsCount",
        ROW_NUMBER() OVER (ORDER BY "DepsCount" DESC NULLS LAST) AS rn
    FROM candidates
) ranked
WHERE rn = 1;