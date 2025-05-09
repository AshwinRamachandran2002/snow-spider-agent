SELECT 
    MAX("answer_count") AS "MAX_ANSWERS"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
WHERE "answer_count" IS NOT NULL
      AND "tags" IS NOT NULL
      /* include Python 2–specific tags … */
      AND (
              "tags" ILIKE '%python-2%'   -- e.g., python-2.x, python-2.7 …
           OR "tags" ILIKE '%python2%'    -- e.g., python2, python27 …
          )
      /* … but exclude anything that references Python 3 */
      AND NOT (
              "tags" ILIKE '%python-3%'   -- e.g., python-3.x, python-3.8 …
           OR "tags" ILIKE '%python3%'    -- e.g., python3, python38 …
          );