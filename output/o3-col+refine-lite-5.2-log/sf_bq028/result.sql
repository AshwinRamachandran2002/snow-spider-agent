/* Top‑8 most‑starred GitHub projects that correspond to the
   latest released version of every NPM package */
WITH latest_npm_release AS (          -- 1. keep only the newest *released* version per NPM package
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC,
                         "SnapshotAt"                      DESC
            ) AS rn
        FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
        WHERE "System" = 'NPM'
          AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE rn = 1
),
latest_projects AS (                  -- 2. keep the most‑recent stats for every GitHub repo
    SELECT
        "Name",
        "StarsCount"
    FROM (
        SELECT
            "Name",
            "StarsCount",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "SnapshotAt" DESC
            ) AS rn
        FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS"
        WHERE "Type" = 'GITHUB'
    )
    WHERE rn = 1
),
npm_to_repo AS (                       -- 3. map package‑versions to GitHub repos
    SELECT DISTINCT
        "Name"        AS pkg_name,
        "Version",
        "ProjectName" AS repo_name
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT"
    WHERE "System"      = 'NPM'
      AND "ProjectType" = 'GITHUB'
)
-- 4. join everything and rank by stars
SELECT
    lr."Name"     AS "Package",
    lr."Version"  AS "Version",
    proj."StarsCount"
FROM latest_npm_release lr
JOIN npm_to_repo   ntr
  ON lr."Name"    = ntr.pkg_name
 AND lr."Version" = ntr."Version"
JOIN latest_projects proj
  ON ntr.repo_name = proj."Name"
QUALIFY ROW_NUMBER() OVER (PARTITION BY lr."Name"
                           ORDER BY proj."StarsCount" DESC) = 1   -- one row per package
ORDER BY proj."StarsCount" DESC NULLS LAST,
         lr."Name"
LIMIT 8;