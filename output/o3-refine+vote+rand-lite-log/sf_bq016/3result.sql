WITH release_versions AS (
    SELECT
        "Name",
        "Version",
        "VersionInfo":"Ordinal"::NUMBER   AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
highest_release AS (
    SELECT "Name", "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            "Ordinal",
            ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Ordinal" DESC, "Version" DESC) AS rn
        FROM release_versions
    )
    WHERE rn = 1
),
dependency_counts AS (
    SELECT
        d."Dependency":"Name"::STRING    AS "Dependency_Name",
        d."Dependency":"Version"::STRING AS "Dependency_Version",
        COUNT(*)                        AS "Occurrences"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN highest_release h
      ON d."System" = 'NPM'
     AND d."Name"   = h."Name"
     AND d."Version"= h."Version"
    GROUP BY
        "Dependency_Name",
        "Dependency_Version"
)
SELECT
    "Dependency_Name",
    "Dependency_Version",
    "Occurrences"
FROM dependency_counts
ORDER BY "Occurrences" DESC NULLS LAST,
         "Dependency_Name",
         "Dependency_Version"
LIMIT 1;