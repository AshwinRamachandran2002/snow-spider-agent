SELECT "title"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE LOWER("title") LIKE '%how%'                                                -- “how” questions
  AND REGEXP_LIKE(                                                               -- android-related tags
        "tags",
        '(^|\|)android([\-a-z0-9]*)?(\||$)',      -- matches android, android-layout, android-intent, …
        'i'
      )
ORDER BY "view_count" DESC NULLS LAST                                            -- most viewed first
LIMIT 1;                                                                         -- top question only