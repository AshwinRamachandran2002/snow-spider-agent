/* Repository that hosts the non-binary Swift file with the highest total “copies” count */
WITH swift_file_copies AS (
    /* Aggregate total copies per unique Swift file */
    SELECT
        "id",
        SUM("copies") AS "total_copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        "binary" = FALSE
        AND LOWER("sample_path") LIKE '%.swift'
    GROUP BY "id"
),
max_copy_value AS (
    /* Determine the maximum copies among Swift files */
    SELECT MAX("total_copies") AS "max_copies"
    FROM swift_file_copies
),
top_swift_ids AS (
    /* Identify the file ID(s) that reach the maximum copies */
    SELECT "id"
    FROM swift_file_copies
    WHERE "total_copies" = (SELECT "max_copies" FROM max_copy_value)
)
SELECT DISTINCT
    "sample_repo_name"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE "id" IN (SELECT "id" FROM top_swift_ids)
ORDER BY "sample_repo_name";