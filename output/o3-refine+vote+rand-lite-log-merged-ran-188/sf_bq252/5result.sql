WITH swift_files AS (
    SELECT
        "id",
        "copies",
        "sample_repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
),
ranked AS (
    SELECT
        "sample_repo_name",
        DENSE_RANK() OVER (ORDER BY "copies" DESC) AS "rank_by_copies"
    FROM swift_files
)
SELECT
    "sample_repo_name"
FROM ranked
WHERE "rank_by_copies" = 1
ORDER BY "sample_repo_name"
LIMIT 1;