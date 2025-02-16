-- Task: List the repository names and languages used in each repository along with the number of bytes per language. Limit the result to 100 rows.
SELECT
    l."repo_name",
    lang.value:"name"::STRING AS "language",
    lang.value:"bytes"::NUMBER AS "language_bytes"
FROM
    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS l,
    LATERAL FLATTEN(input => l."language") AS lang
LIMIT 100;