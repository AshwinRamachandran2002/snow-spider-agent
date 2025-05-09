WITH pkgs AS (
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR(TRIM(f.value::STRING), '\"[^\"]+\"'),   -- first "pkg/name"
      '\"',                                                 -- strip quotes
      ''
    ) AS pkg
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
       LATERAL FLATTEN(
         input => SPLIT(
                    REGEXP_REPLACE(
                      REGEXP_SUBSTR("content", 'import[\\s\\S]*?\\)', 1, 1, 'e'), -- whole import (…) block
                      '^import\\s*\\(|\\)$',                                      -- drop leading “import (” & trailing “)”
                      ''
                    ),
                    '\n'                                                          -- break multi-line list
                  )
       ) f
  WHERE ("content" ILIKE '%import (%' OR "content" ILIKE '%import(%')              -- files that contain import ( … )
    AND REGEXP_SUBSTR(TRIM(f.value::STRING), '\"[^\"]+\"') IS NOT NULL             -- keep lines with "pkg"
    AND TRIM(f.value::STRING) <> ''
)

SELECT
  pkg       AS package,
  COUNT(*)  AS imports_count
FROM pkgs
WHERE pkg IS NOT NULL
GROUP BY pkg
ORDER BY imports_count DESC NULLS LAST
LIMIT 10;