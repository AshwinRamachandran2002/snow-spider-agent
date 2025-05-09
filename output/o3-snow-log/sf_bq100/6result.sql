/* Top-10 most frequently imported packages found inside multi-line
   “import (…)” blocks (quotes removed) */
SELECT
  package,
  COUNT(*) AS pkg_freq
FROM (
  /* 1) pull every import-block, split into lines, keep *one* line per row */
  SELECT
    REGEXP_SUBSTR(f.value::STRING, '"([^"]+)"', 1, 1, 'e', 1) AS package
  FROM (
    SELECT
      REGEXP_SUBSTR("content",
                    'import\\s*\\(([^)]*)\\)',          -- grab text in (…) 
                    1, 1, 'es', 1) AS import_block
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
  ) c,
  LATERAL FLATTEN(INPUT => SPLIT(c.import_block, '\n')) f
) t
WHERE package IS NOT NULL                       -- 2) ignore blank lines
GROUP BY package                                -- 3) count occurrences
ORDER BY pkg_freq DESC NULLS LAST               -- 4) most-used first
LIMIT 10;