WITH latest_release AS (
    SELECT
        "Name"  AS pkg_name,
        "Version" AS pkg_version
    FROM (
        SELECT
            "Name",
            "Version",
            TRY_PARSE_JSON("VersionInfo")                         AS vi,
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY (vi:"Ordinal"::NUMBER) DESC) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND TRY_PARSE_JSON("VersionInfo"):"IsRelease"::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
all_deps AS (
    SELECT DISTINCT
        l.pkg_name,
        l.pkg_version,
        d."Dependency":"Name"::TEXT    AS dep_name,
        d."Dependency":"Version"::TEXT AS dep_version
    FROM latest_release l
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System"  = 'NPM'
     AND d."Name"    = l.pkg_name
     AND d."Version" = l.pkg_version
    WHERE d."Dependency" IS NOT NULL
),
dependency_freq AS (
    SELECT
        dep_name,
        dep_version,
        COUNT(*) AS freq
    FROM all_deps
    GROUP BY dep_name,
             dep_version
)
SELECT
    dep_name      AS "DependencyName",
    dep_version   AS "DependencyVersion",
    freq          AS "Frequency"
FROM dependency_freq
ORDER BY freq DESC, dep_name, dep_version
LIMIT 1;