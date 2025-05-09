SELECT COUNT(*) AS "PULL_REQUEST_CREATION_EVENTS"
FROM (
    /* Pull‑request creation events on 2023‑01‑18 */
    SELECT
        "repo":"name"::string AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE "type" = 'PullRequestEvent'
      AND "payload" LIKE '%"action":"opened"%'
      /* `created_at` stored as microseconds since epoch */
      AND DATE_TRUNC(
              'DAY',
              TO_TIMESTAMP_LTZ("created_at" / 1000000)
          ) = '2023-01-18'
) pr
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES lang
  ON pr.repo_name = lang."repo_name"
WHERE LOWER(lang."language"::string) LIKE '%javascript%';