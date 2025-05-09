WITH imports AS (
  SELECT
      REGEXP_REPLACE(
          REGEXP_SUBSTR(
              l.value,
              '\\bimport\\s+([A-Za-z0-9_\\.]+\\.[A-Za-z0-9_\\*]+)',
              1, 1, 'e', 1
          ),
          '\\.[A-Za-z0-9_\\*]+$',
          ''
      ) AS "package_name"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
       LATERAL SPLIT_TO_TABLE(c."content", '\n') l
  WHERE c."sample_path" ILIKE '%.java'
    AND l.value ILIKE '%import %'
)
SELECT
  "package_name",
  COUNT(*) AS "import_occurrences"
FROM imports
WHERE "package_name" IS NOT NULL
  AND "package_name" <> ''
GROUP BY "package_name"
ORDER BY "import_occurrences" DESC NULLS LAST
LIMIT 10;