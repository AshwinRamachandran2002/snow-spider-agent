SELECT
  "package_name",
  COUNT(*) AS "Count"
FROM
  (
    SELECT
      REGEXP_SUBSTR(
        LINES.VALUE::STRING,
        'import\\s+([\\w\\.\\*]+);',
        1,
        1,
        'e',
        1
      ) AS "package_name"
    FROM
      GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS,
      LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) LINES
    WHERE
      "sample_path" LIKE '%.java'
      AND "binary" = FALSE
      AND "content" ILIKE '%import%'
      AND LINES.VALUE::STRING ILIKE 'import%'
  ) AS IMPORTED_PACKAGES
WHERE
  "package_name" IS NOT NULL
GROUP BY
  "package_name"
ORDER BY
  "Count" DESC NULLS LAST
LIMIT 10;