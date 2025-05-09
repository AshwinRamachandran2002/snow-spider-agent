WITH releases AS (  -- all NPM package versions that are *releases*
    SELECT
        "Name",
        "Version",
        COALESCE(("VersionInfo":"Ordinal")::NUMBER ,0)         AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
),
highest AS (         -- highest‑ordinal release version per package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "Ordinal",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Ordinal" DESC) AS rn
        FROM releases
    )
    WHERE rn = 1
),
deps_of_highest AS ( -- dependencies of those highest‑release versions
    SELECT
        d."Dependency":"Name"::TEXT    AS dep_name,
        d."Dependency":"Version"::TEXT AS dep_version
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN highest h
          ON d."System"  = 'NPM'
         AND d."Name"    = h."Name"
         AND d."Version" = h."Version"
    WHERE d."Dependency":"System"::TEXT = 'NPM'
),
counts AS (          -- how often each dependency appears
    SELECT
        dep_name,
        dep_version,
        COUNT(*) AS cnt
    FROM deps_of_highest
    GROUP BY dep_name, dep_version
)
SELECT
    dep_name    AS "DependencyName",
    dep_version AS "DependencyVersion",
    cnt         AS "Occurrences"
FROM counts
ORDER BY cnt DESC NULLS LAST, dep_name
LIMIT 1;