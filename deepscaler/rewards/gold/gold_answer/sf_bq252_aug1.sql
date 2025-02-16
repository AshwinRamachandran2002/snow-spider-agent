-- Task: List all unique files in the dataset (based on file ID), along with their repository names and paths.
SELECT
    f."id",
    MIN(f."repo_name") AS "repo_name",
    MIN(f."path") AS "path"
FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
GROUP BY
    f."id";