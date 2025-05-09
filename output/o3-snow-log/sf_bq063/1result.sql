WITH released_versions AS (
    /* All released (IsRelease = true) NPM package versions whose names do NOT contain “@” */
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        pv."SnapshotAt",
        pv."VersionInfo":"Ordinal"::NUMBER          AS "Ordinal",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST,
                     pv."SnapshotAt"                  DESC
        )                                            AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"  pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE)
), latest_release_per_pkg AS (
    /* Keep only the latest released version for every package */
    SELECT *
    FROM released_versions
    WHERE rn = 1
), dependency_counts AS (
    /* Count dependencies for every (Name,Version) pair */
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS dep_count
    FROM DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
), candidate_pkgs AS (
    /* Join latest releases with their dependency counts */
    SELECT
        lrp."Name",
        lrp."Version",
        lrp."Links",
        COALESCE(dc.dep_count, 0) AS dep_count
    FROM latest_release_per_pkg lrp
    LEFT JOIN dependency_counts dc
           ON  lrp."Name"    = dc."Name"
           AND lrp."Version" = dc."Version"
), pkg_with_max_deps AS (
    /* Package whose latest release has the highest dependency count */
    SELECT *
    FROM candidate_pkgs
    ORDER BY dep_count DESC NULLS LAST
    LIMIT 1
)
SELECT
    flt.value:"URL"::STRING AS "GitHub_Source_Repo_URL"
FROM pkg_with_max_deps,
     LATERAL FLATTEN(input => pkg_with_max_deps."Links") flt
WHERE flt.value:"Label"::STRING = 'SOURCE_REPO'
  AND POSITION('github.com', flt.value:"URL"::STRING) > 0
LIMIT 1;