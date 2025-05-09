SELECT 
    "title"
FROM 
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE 
    LOWER("title") LIKE '%how%' 
    AND (
        "tags" LIKE '%android-layout%' 
        OR "tags" LIKE '%android-activity%' 
        OR "tags" LIKE '%android-intent%' 
        OR "tags" LIKE '%android%'          -- covers other android-related tags
    )
ORDER BY 
    "view_count" DESC NULLS LAST
LIMIT 1;