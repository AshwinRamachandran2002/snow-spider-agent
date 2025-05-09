WITH imports AS (
  /* 1) Extract the imported package from each Java import line */
  SELECT
    REGEXP_REPLACE(
      /* Capture group #2 returns the fully-qualified import target
         (group #1 is the optional keyword "static ") */
      REGEXP_SUBSTR(
        f.value::STRING,
        '\\s*import\\s+(static\\s+)?([A-Za-z_][A-Za-z0-9_.]*)',
        1,                     -- start position
        1,                     -- first occurrence
        '',                    -- default regexp parameters
        2                      -- return capture group #2
      ),
      '\\.[^.]+$',             -- strip the last segment (class/enum/etc.)
      ''
    ) AS "package_name"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
       LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f
  WHERE sc."sample_path" ILIKE '%.java'
    AND f.value::STRING ILIKE 'import %'
),
package_counts AS (
  /* 2) Count how many times each package is imported */
  SELECT
    "package_name",
    COUNT(*) AS "total_imports"
  FROM imports
  WHERE "package_name" IS NOT NULL
    AND "package_name" <> ''
  GROUP BY "package_name"
)
/* 3) Return the 10 most frequently imported packages */
SELECT
  "package_name",
  "total_imports"
FROM package_counts
ORDER BY "total_imports" DESC NULLS LAST
LIMIT 10;