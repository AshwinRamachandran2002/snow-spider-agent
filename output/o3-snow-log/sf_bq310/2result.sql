SELECT 
    "title"
FROM 
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE 
    LOWER("title") LIKE 'how%'                               -- “how” question
    AND LOWER("tags") LIKE '%android-%'                      -- android-specific tags (e.g., android-layout, android-activity,…)
ORDER BY 
    "view_count" DESC NULLS LAST                             -- most viewed first
LIMIT 1;                                                     -- keep only the top result