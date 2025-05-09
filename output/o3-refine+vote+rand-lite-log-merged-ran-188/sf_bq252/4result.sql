WITH "swift_files" AS (
    SELECT
        "id",
        "sample_repo_name",
        "copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
)
SELECT
    "sample_repo_name"
FROM "swift_files"
ORDER BY
    "copies" DESC NULLS LAST,
    "id"     ASC
LIMIT 1;