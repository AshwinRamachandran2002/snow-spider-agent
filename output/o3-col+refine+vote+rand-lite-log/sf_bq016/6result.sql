WITH ranked_releases AS (   -- all release versions of NPM packages, ranked by Ordinal
    SELECT
        "Name",
        "Version",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY (PARSE_JSON("VersionInfo"):"Ordinal"::INTEGER) DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE
        "System" = 'NPM'
        AND COALESCE(PARSE_JSON("VersionInfo"):"IsRelease"::BOOLEAN, FALSE)
),
highest_release AS (       -- keep only the highest-ordinal (latest) release per package
    SELECT "Name", "Version"
    FROM ranked_releases
    WHERE rn = 1
),
deps_expanded AS (         -- expand dependency objects for those highest releases
    SELECT
        PARSE_JSON(d."Dependency"):"Name"::STRING    AS dep_name,
        PARSE_JSON(d."Dependency"):"Version"::STRING AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN highest_release h
        ON  d."System"  = 'NPM'
        AND d."Name"    = h."Name"
        AND d."Version" = h."Version"
)
SELECT
    dep_name        AS "DependencyName",
    dep_version     AS "DependencyVersion",
    COUNT(*)        AS "Appearances"
FROM deps_expanded
GROUP BY dep_name, dep_version
ORDER BY "Appearances" DESC NULLS LAST
LIMIT 1;