WITH "swift_files" AS (
    SELECT 
        "id",
        "copies",
        "sample_repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE 
        "binary" = FALSE
        AND LOWER("sample_path") LIKE '%.swift'
)
SELECT 
    "sample_repo_name"
FROM "swift_files"
ORDER BY 
    "copies" DESC NULLS LAST,
    "id"
LIMIT 1;