WITH "RELEASE_VERSIONS" AS (
    SELECT
        "Name",
        "Version",
        COALESCE("VersionInfo":"Ordinal"::NUMBER, 0) AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE
        "System" = 'NPM'
        AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
"HIGHEST_RELEASE" AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "Ordinal",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Ordinal" DESC) AS "rn"
        FROM "RELEASE_VERSIONS"
    )
    WHERE "rn" = 1
),
"DEPENDENCY_COUNTS" AS (
    SELECT
        d."Dependency":"Name"::TEXT   AS "DependencyName",
        d."Dependency":"Version"::TEXT AS "DependencyVersion",
        COUNT(*) AS "Appearances"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN "HIGHEST_RELEASE" h
      ON d."System" = 'NPM'
     AND d."Name" = h."Name"
     AND d."Version" = h."Version"
    WHERE d."Dependency":"System"::TEXT = 'NPM'
    GROUP BY
        d."Dependency":"Name"::TEXT,
        d."Dependency":"Version"::TEXT
),
"RANKED" AS (
    SELECT
        "DependencyName",
        "DependencyVersion",
        "Appearances",
        ROW_NUMBER() OVER (ORDER BY "Appearances" DESC, "DependencyName", "DependencyVersion") AS "rn"
    FROM "DEPENDENCY_COUNTS"
)
SELECT
    "DependencyName",
    "DependencyVersion",
    "Appearances"
FROM "RANKED"
WHERE "rn" = 1;