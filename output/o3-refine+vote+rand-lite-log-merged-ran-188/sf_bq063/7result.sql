WITH latest_release AS (
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        TRY_TO_NUMBER(pv."VersionInfo":"Ordinal"::string)                  AS "Ordinal",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY TRY_TO_NUMBER(pv."VersionInfo":"Ordinal"::string) DESC NULLS LAST,
                     pv."Version" DESC
        )                                                                AS "rn"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                         -- exclude scoped packages
      AND COALESCE((pv."VersionInfo":"IsRelease")::BOOLEAN, FALSE)
  ),                                                           -- keep only released versions
latest_per_pkg AS (
    SELECT * FROM latest_release WHERE "rn" = 1               -- latest release per package
),
dep_counts AS (
    SELECT
        lp."Name",
        lp."Version",
        lp."Links",
        COUNT(d."Dependency")                                  AS "DepCount"
    FROM latest_per_pkg lp
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
           ON d."System"  = 'NPM'
          AND d."Name"    = lp."Name"
          AND d."Version" = lp."Version"
    GROUP BY lp."Name", lp."Version", lp."Links"
),
top_pkg AS (                                                   -- package with most dependencies
    SELECT *
    FROM dep_counts
    ORDER BY "DepCount" DESC NULLS LAST, "Name" ASC
    LIMIT 1
)
SELECT
    lf.value:"URL"::string AS "GitHub_URL"
FROM top_pkg tp,
     LATERAL FLATTEN(input => tp."Links") lf
WHERE lf.value:"Label"::string = 'SOURCE_REPO'
  AND lf.value:"URL"::string ILIKE '%github.com%'
LIMIT 1;