-- Task: From the GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS table, parse the JSON-formatted "content" column to extract the "require" section (which contains package dependencies), extract all package names listed as keys in the "require" section, and count the frequency of each package name across all records, ordering the results in descending order of count.
WITH json_files AS (
  SELECT
    c."id",
    TRY_PARSE_JSON(c."content"):"require" AS "dependencies"
  FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
),
package_names AS (
  SELECT
    f.key AS "package_name"
  FROM
    json_files,
    LATERAL FLATTEN(input => "dependencies") AS f
)
SELECT
  "package_name",
  COUNT(*) AS "count"
FROM
  package_names
WHERE
  "package_name" IS NOT NULL
GROUP BY
  "package_name"
ORDER BY
  "count" DESC;