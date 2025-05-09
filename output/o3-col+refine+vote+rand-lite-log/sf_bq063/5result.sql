WITH latest AS (   -- latest released version (non-scoped) for every NPM package
    SELECT  v."Name",
            v."Version"
    FROM    DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS v
    JOIN (  SELECT  "Name",
                    MAX("VersionInfo":"Ordinal"::NUMBER) AS "Latest_Ordinal"
            FROM    DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
            WHERE   "System" = 'NPM'
              AND   "Name" NOT LIKE '@%'
              AND   "VersionInfo":"IsRelease"::BOOLEAN = TRUE
            GROUP BY "Name"
          ) lo
      ON  v."Name" = lo."Name"
     AND  v."VersionInfo":"Ordinal"::NUMBER = lo."Latest_Ordinal"
    WHERE   v."System" = 'NPM'
      AND   v."Name"  NOT LIKE '@%'
      AND   v."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
dep_counts AS (   -- dependency count of each of those latest versions
    SELECT  d."Name",
            d."Version",
            COUNT(*) AS "Deps_Count"
    FROM    DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN    latest l
           ON d."Name"    = l."Name"
          AND d."Version" = l."Version"
    WHERE   d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
)
SELECT  l.value:"URL"::STRING  AS "GitHub_URL"
FROM    dep_counts dc
JOIN    DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
       ON p."Name"    = dc."Name"
      AND p."Version" = dc."Version",
        LATERAL FLATTEN(input => p."Links") l
WHERE   l.value:"Label"::STRING = 'SOURCE_REPO'
  AND   l.value:"URL"::STRING   ILIKE '%github.com%'
ORDER BY dc."Deps_Count" DESC NULLS LAST
LIMIT 1;