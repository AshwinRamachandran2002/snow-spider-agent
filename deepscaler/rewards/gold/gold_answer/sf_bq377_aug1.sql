-- Task: List all package names from the 'require' section of JSON-formatted content (limit to 100 results)
WITH json_files AS (
  SELECT
    c."id",
    TRY_PARSE_JSON(c."content"):"require" AS "dependencies"
  FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
)
SELECT
  f.key AS "package_name"
FROM
  json_files,
  LATERAL FLATTEN(input => "dependencies") AS f
WHERE
  f.key IS NOT NULL
LIMIT 100;