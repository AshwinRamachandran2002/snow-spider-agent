WITH repos_with_python AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(INPUT => "language") v
    WHERE LOWER(v.value:"name"::string) LIKE '%python%'
),
repos_without_python AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "repo_name" NOT IN (SELECT "repo_name" FROM repos_with_python)
)
SELECT
    COUNT(CASE WHEN LOWER(sc."sample_path") LIKE '%readme.md%'
             AND LOWER(sc."content") LIKE '%copyright (c)%' THEN 1 END)::FLOAT /
    COUNT(*)::FLOAT AS Proportion
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
WHERE sc."sample_repo_name" IN (SELECT "repo_name" FROM repos_without_python);