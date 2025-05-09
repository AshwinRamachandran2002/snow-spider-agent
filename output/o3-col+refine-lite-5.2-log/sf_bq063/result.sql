WITH latest_release AS (  -- most‑recent *released* version for every NPM package w/o “@”
    SELECT pv."Name",
           pv."Version"
    FROM   "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"  pv
    WHERE  pv."System" = 'NPM'
      AND  pv."Name"   NOT ILIKE '%@%'
      AND  pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pv."Name"
                               ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC) = 1
),
dep_counts AS (          -- how many dependencies each (Name,Version) pulls in
    SELECT d."Name",
           d."Version",
           COUNT(*) AS "DepCount"
    FROM   "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    WHERE  d."System" = 'NPM'
    GROUP  BY d."Name", d."Version"
),
top_pkg AS (             -- the single package whose latest release has the most deps
    SELECT lr."Name",
           lr."Version",
           dc."DepCount"
    FROM   latest_release lr
    JOIN   dep_counts     dc
           ON  lr."Name"    = dc."Name"
           AND lr."Version" = dc."Version"
    ORDER  BY dc."DepCount" DESC,
              lr."Name"     ASC          -- secondary tie‑breaker
    LIMIT  1
)
SELECT tp."Name",
       tp."Version",
       l.value:"URL"::STRING AS "GitHubSourceRepoURL"
FROM   top_pkg                                      tp
JOIN   "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
       ON  pv."Name"    = tp."Name"
       AND pv."Version" = tp."Version",
       LATERAL FLATTEN(input => pv."Links")          l
WHERE  l.value:"Label"::STRING = 'SOURCE_REPO'
  AND  l.value:"URL"::STRING   ILIKE '%github.com%';