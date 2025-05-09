SELECT
  import_package,
  COUNT(*) AS cnt
FROM (
  /* Extract package part from every Java import line */
  SELECT
    REGEXP_SUBSTR(
      REGEXP_SUBSTR(f.value::STRING, '\\s*import\\s+([^;]+)', 1, 1, 'e'),
      '([A-Za-z0-9_\\.]+)\\.[A-Za-z0-9_*]+',
      1, 1, 'e', 1
    ) AS import_package
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
       LATERAL FLATTEN(INPUT => SPLIT(t."content", '\n')) f
  WHERE t."sample_path" ILIKE '%.java'            -- only Java files
    AND f.value::STRING ILIKE 'import %'          -- only import lines
) s
WHERE import_package IS NOT NULL                  -- drop non-matches
GROUP BY import_package
ORDER BY cnt DESC NULLS LAST                      -- most frequent first
LIMIT 10;                                         -- top-10 packages