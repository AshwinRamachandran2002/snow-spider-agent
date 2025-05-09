WITH all_photos AS (    
    SELECT "user"
    FROM ECLIPSE_MEGAMOVIE.ECLIPSE_MEGAMOVIE.PHOTOS_V_0_1
    
    UNION ALL
    
    SELECT "user"
    FROM ECLIPSE_MEGAMOVIE.ECLIPSE_MEGAMOVIE.PHOTOS_V_0_2
    
    UNION ALL
    
    SELECT "user"
    FROM ECLIPSE_MEGAMOVIE.ECLIPSE_MEGAMOVIE.PHOTOS_V_0_3
)

SELECT
    "user"          AS "user_id",
    COUNT(*)        AS "total_clicks"
FROM all_photos
WHERE "user" IS NOT NULL
GROUP BY "user"
ORDER BY "total_clicks" DESC NULLS LAST
LIMIT 1;