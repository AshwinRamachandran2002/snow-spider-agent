WITH latest_pkg_versions AS (   /* keep only the newest snapshot of every package version */
    SELECT
        "System",
        "Name",
        "Version",
        "Licenses",
        ROW_NUMBER() OVER (PARTITION BY "System", "Name", "Version" 
                           ORDER BY "SnapshotAt" DESC) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
),
dedup AS (                       /* deduplicated package versions */
    SELECT
        "System",
        "Licenses"
    FROM latest_pkg_versions
    WHERE rn = 1
),
license_counts AS (              /* count how often every license occurs per system */
    SELECT
        d."System",
        f.value::string  AS "License",
        COUNT(*)         AS "PkgCount"
    FROM dedup d,
         LATERAL FLATTEN(input => d."Licenses") f
    WHERE f.value IS NOT NULL
    GROUP BY d."System", f.value::string
),
ranked AS (                      /* rank licenses by frequency inside each system */
    SELECT
        "System",
        "License",
        "PkgCount",
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY "PkgCount" DESC, "License") AS rnk
    FROM license_counts
)
SELECT
    "System",
    "License"     AS "MostFrequentLicense",
    "PkgCount"    AS "PackageCount"
FROM ranked
WHERE rnk = 1
ORDER BY "System";