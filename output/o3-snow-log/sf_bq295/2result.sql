WITH python_repos AS (
    /* Repositories that contain at least one .py file
       smaller than 15 000 B with the substring 'def ' */
    SELECT DISTINCT sf."repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    sf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON  sc."sample_repo_name" = sf."repo_name"
           AND sc."sample_path"      = sf."path"
    WHERE  sf."path" ILIKE '%.py'
      AND  sc."binary" = FALSE
      AND  sc."size"   < 15000
      AND  POSITION('def ' IN sc."content") > 0
)
SELECT  sr."repo_name",
        sr."watch_count" AS watch_events_2017
FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_REPOS sr
JOIN    python_repos                          pr
       ON pr."repo_name" = sr."repo_name"
ORDER BY sr."watch_count" DESC NULLS LAST
LIMIT 3;