WITH python_repos AS (                             -- repos with at least one qualifying Python file
    SELECT DISTINCT f."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON c."id" = f."id"
    WHERE LOWER(f."path") LIKE '%.py'              -- Python source file
      AND c."size" < 15000                         -- file < 15 KB
      AND POSITION('def ' IN c."content") > 0      -- contains "def "
)

SELECT r."repo_name",
       r."watch_count" AS watch_event_count
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_REPOS r
JOIN   python_repos p
  ON   p."repo_name" = r."repo_name"
ORDER  BY watch_event_count DESC NULLS LAST
LIMIT 3;