SELECT
  "package_name" AS "PackageName",
  COUNT(*) AS "ImportCount"
FROM (
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(TRIM(s.VALUE), '^import\\s+', '', 1, 0, ''),
          '^static\\s+', '', 1, 0, ''
        ),
        '\\s*;.*$', '', 1, 0, ''
      ),
      '\\.[^\\.]+$', '', 1, 0, ''
    ) AS "package_name"
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS t,
    LATERAL SPLIT_TO_TABLE(t."content", '\n') AS s
  WHERE
    t."sample_path" LIKE '%.java' AND TRIM(s.VALUE) LIKE 'import %'
) AS "imports"
WHERE "package_name" != ''
GROUP BY "package_name"
ORDER BY "ImportCount" DESC NULLS LAST
LIMIT 10;