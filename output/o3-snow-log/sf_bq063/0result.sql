WITH pv_filtered AS (
    /* NPM package versions that are releases, do not contain '@' in the name,
       and have a SOURCE_REPO link pointing at GitHub */
    SELECT
        pv."Name",
        pv."Version",
        -- extract the GitHub SOURCE_REPO URL
        MAX(
            CASE
                WHEN link.value:"Label"::string = 'SOURCE_REPO'
                     AND link.value:"URL"::string ILIKE '%github.com%'
                THEN link.value:"URL"::string
            END
        )                                            AS "URL",
        pv."VersionInfo":"Ordinal"::NUMBER           AS "Ordinal"
    FROM
        DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS  pv,
        LATERAL FLATTEN(INPUT => pv."Links") link
    WHERE
        pv."System" = 'NPM'
        AND pv."Name" NOT LIKE '%@%'                           -- exclude scoped packages
        AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE       -- released versions only
    GROUP BY
        pv."Name",
        pv."Version",
        pv."VersionInfo":"Ordinal"
    HAVING
        "URL" IS NOT NULL                                      -- keep rows that have a GitHub SOURCE_REPO
),
deps_count AS (
    /* Count the number of dependencies for each (Name, Version) */
    SELECT
        p."Name",
        p."Version",
        p."URL",
        p."Ordinal",
        COUNT(d."Dependency")         AS "DepCount"
    FROM
        pv_filtered                 p
        LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
               ON  d."System"  = 'NPM'
               AND d."Name"    = p."Name"
               AND d."Version" = p."Version"
    GROUP BY
        p."Name",
        p."Version",
        p."URL",
        p."Ordinal"
),
latest_release_per_pkg AS (
    /* Keep only the latest released version (highest Ordinal) per package */
    SELECT *
    FROM  (
        SELECT
            dc.*,
            ROW_NUMBER() OVER (PARTITION BY dc."Name"
                               ORDER BY dc."Ordinal" DESC NULLS LAST) AS rn
        FROM deps_count dc
    )
    WHERE rn = 1
),
ranked_by_deps AS (
    /* Rank packages by their dependency count */
    SELECT
        l.*,
        ROW_NUMBER() OVER (ORDER BY l."DepCount" DESC NULLS LAST) AS rnk
    FROM latest_release_per_pkg l
)
SELECT
    "URL"
FROM
    ranked_by_deps
WHERE
    rnk = 1;