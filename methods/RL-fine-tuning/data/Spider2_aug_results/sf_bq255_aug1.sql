-- Task: How many repositories use the 'Shell' programming language and have the 'apache-2.0' license?
SELECT
  COUNT(DISTINCT lang_table."repo_name") AS "num_repos"
FROM
(
  SELECT
    L."repo_name",
    language_struct.value:"name"::STRING AS "language_name"
  FROM
    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS L,
    LATERAL FLATTEN(input => L."language") AS language_struct
) AS lang_table
JOIN
  GITHUB_REPOS.GITHUB_REPOS.LICENSES AS license_table
ON
  license_table."repo_name" = lang_table."repo_name"
WHERE
  license_table."license" LIKE 'apache-2.0'
  AND lang_table."language_name" LIKE 'Shell';