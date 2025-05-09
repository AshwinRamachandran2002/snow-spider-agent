SELECT
  "package_name",
  COUNT(*) AS "usage_count"
FROM (
  SELECT
    REGEXP_REPLACE(
      f.value::STRING,
      '^\\s*import\\s+([A-Za-z0-9_\\.]+)\\.[A-Za-z0-9_\\*]+\\s*;.*$',
      '\\1'
    ) AS "package_name"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
       LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) AS f
  WHERE c."sample_path" ILIKE '%.java'
    AND f.value::STRING ILIKE 'import %;'
    AND REGEXP_LIKE(
          f.value::STRING,
          '^\\s*import\\s+[A-Za-z0-9_\\.]+\\.[A-Za-z0-9_\\*]+\\s*;'
        )
) AS pkg
GROUP BY "package_name"
ORDER BY "usage_count" DESC NULLS LAST
LIMIT 10;