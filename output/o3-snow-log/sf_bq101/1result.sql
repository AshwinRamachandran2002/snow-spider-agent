/* Top 10 most frequently imported Java packages (Snowflake-compatible) */
SELECT
  import_package,
  COUNT(*) AS import_count
FROM (
  /* keep only the package portion (everything before the last dot) */
  SELECT
    REGEXP_SUBSTR(full_import,
                  '([a-zA-Z0-9_\\.]+)\\.[^.]+$',
                  1, 1, 'c', 1) AS import_package
  FROM (
    /* extract the full import target from each “import …” line */
    SELECT
      REGEXP_SUBSTR(
        TRIM(line.value),
        'import\\s+([a-zA-Z0-9_\\.]+(\\.[a-zA-Z0-9_\\*]+)?)',
        1, 1, 'c', 1
      ) AS full_import
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS sc,
         LATERAL SPLIT_TO_TABLE(sc."content", '\n') AS line
    WHERE sc."sample_path" ILIKE '%.java'            -- only Java files
      AND TRIM(line.value) ILIKE 'import %'          -- only import lines
  )
  WHERE full_import IS NOT NULL
)
GROUP BY import_package
ORDER BY import_count DESC NULLS LAST
LIMIT 10;