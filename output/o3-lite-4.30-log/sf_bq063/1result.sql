WITH candidate_versions AS (                                       -- release versions that have a GitHub SOURCE_REPO link
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        f.value:"URL"::STRING AS url
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN(input => pv."Links") f
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                                -- exclude scoped packages
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE            -- released versions
      AND f.value:"Label"::STRING = 'SOURCE_REPO'
      AND f.value:"URL"::STRING ILIKE '%github.com%'              -- GitHub link
),
latest_per_pkg AS (                                                -- latest release (with GitHub link) per package
    SELECT
        "Name",
        "Version",
        url
    FROM (
        SELECT
            "Name",
            "Version",
            url,
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "SnapshotAt" DESC) AS rn
        FROM candidate_versions
    )
    WHERE rn = 1
),
top_pkg AS (                                                       -- choose the package whose latest release has most deps
    SELECT
        lp."Name",
        lp."Version",
        lp.url AS source_repo,
        COUNT(d."Dependency") AS dep_cnt
    FROM latest_per_pkg lp
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System" = 'NPM'
     AND d."Name"   = lp."Name"
     AND d."Version"= lp."Version"
    GROUP BY lp."Name", lp."Version", lp.url
    ORDER BY dep_cnt DESC NULLS LAST, lp."Name"
    LIMIT 1
)
SELECT source_repo AS "SOURCE_REPO"
FROM   top_pkg;