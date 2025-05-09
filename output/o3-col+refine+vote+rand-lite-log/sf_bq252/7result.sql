WITH max_copies AS (
    SELECT MAX("copies") AS "max_copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
)
SELECT DISTINCT
       "sample_repo_name"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS,
       max_copies
WHERE  "binary" = FALSE
  AND  LOWER("sample_path") LIKE '%.swift'
  AND  "copies" = max_copies."max_copies";