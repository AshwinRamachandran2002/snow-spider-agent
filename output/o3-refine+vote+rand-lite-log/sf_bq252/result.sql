WITH swift_files AS (
    SELECT
        "id",
        "copies",
        "sample_repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
),
most_copied_file AS (      -- identify the Swift file with the highest copy count
    SELECT "id"
    FROM (
        SELECT
            "id",
            MAX("copies") AS copies
        FROM swift_files
        GROUP BY "id"
        ORDER BY copies DESC NULLS LAST, "id"
        LIMIT 1
    )
)
SELECT
    "sample_repo_name"
FROM swift_files
WHERE "id" = (SELECT "id" FROM most_copied_file)
ORDER BY "sample_repo_name"
LIMIT 1;