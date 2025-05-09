WITH top_release AS (
    /* 1) Keep only the latest *release* version for every NPM package */
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal"::NUMBER) DESC NULLS LAST
            ) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND ("VersionInfo":"IsRelease"::BOOLEAN) = TRUE
    )
    WHERE rn = 1
),
dep_counts AS (
    /* 2) Count how often each (dependency-name, dependency-version) occurs */
    SELECT
        d."Dependency":"Name"::STRING    AS "DepName",
        d."Dependency":"Version"::STRING AS "DepVersion",
        COUNT(*)                        AS "Appearances"
    FROM top_release t
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System"  = 'NPM'
     AND d."Name"    = t."Name"
     AND d."Version" = t."Version"
    GROUP BY
        d."Dependency":"Name"::STRING,
        d."Dependency":"Version"::STRING
)
/* 3) Return the single most-frequent dependency among latest releases */
SELECT
    "DepName",
    "DepVersion",
    "Appearances"
FROM dep_counts
ORDER BY "Appearances" DESC NULLS LAST
LIMIT 1;