WITH swift_files AS (
  SELECT
    "id",
    "sample_repo_name",
    "copies"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
  WHERE
    "binary" = FALSE
    AND "sample_path" ILIKE '%.swift'
)
SELECT
  "sample_repo_name" AS "repo_with_most_copied_swift"
FROM swift_files
ORDER BY
  "copies" DESC NULLS LAST
LIMIT 1;