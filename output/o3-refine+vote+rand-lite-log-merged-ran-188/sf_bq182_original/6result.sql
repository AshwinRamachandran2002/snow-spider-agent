WITH PR_EVENTS AS (   -- pull‑request events on 2023‑01‑18
    SELECT
        "repo":"name"::string AS REPO_NAME
    FROM GITHUB_REPOS_DATE.YEAR._2023
    WHERE "type" = 'PullRequestEvent'
      AND DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000)) = '2023-01-18'
),

PRIMARY_LANGUAGE_PER_REPO AS (  -- language with most bytes per repo
    SELECT
        L."repo_name"                      AS REPO_NAME,
        F.value:"language"::string         AS LANGUAGE,
        F.value:"bytes"::number            AS BYTES,
        ROW_NUMBER() OVER (PARTITION BY L."repo_name"
                           ORDER BY F.value:"bytes"::number DESC) AS RN
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES L,
         LATERAL FLATTEN(INPUT => L."language") F
),

REPO_LANG AS (   -- keep only primary language
    SELECT REPO_NAME, LANGUAGE
    FROM PRIMARY_LANGUAGE_PER_REPO
    WHERE RN = 1
)

SELECT
    RL.LANGUAGE
FROM PR_EVENTS E
JOIN REPO_LANG RL
  ON E.REPO_NAME = RL.REPO_NAME
GROUP BY RL.LANGUAGE
HAVING COUNT(*) >= 100
ORDER BY RL.LANGUAGE;