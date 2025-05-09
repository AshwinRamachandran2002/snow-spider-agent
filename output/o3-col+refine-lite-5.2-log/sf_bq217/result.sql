SELECT
       COUNT(*) AS "pull_request_opened_events"
FROM   GITHUB_REPOS_DATE.YEAR."_2023" AS e
JOIN  (
        /* repositories that list JavaScript among their languages */
        SELECT DISTINCT l."repo_name"
        FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS l,
               LATERAL FLATTEN(input => l."language") AS lang
        WHERE  lang.value:"name"::STRING = 'JavaScript'
      ) AS js
      ON js."repo_name" = e."repo":"name"::STRING
WHERE  e."type" = 'PullRequestEvent'
  AND  PARSE_JSON(e."payload"):action::STRING = 'opened'
  /* micro‑second epoch for 2023‑01‑18 UTC */
  AND  e."created_at" >= 1674000000000000
  AND  e."created_at" <  1674086400000000;