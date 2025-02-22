-- Task: From July 1, 2019 through December 31, 2019, for all users with IDs between 16712208 and 18712208 on Stack Overflow, retrieve the user ID and the tags of the questions they authored.
SELECT 
    "owner_user_id" AS "User_ID", 
    "tags" AS "Tags"
FROM 
    "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS"
WHERE 
    "owner_user_id" BETWEEN 16712208 AND 18712208
    AND "creation_date" BETWEEN 1561939200000000 AND 1577836799000000;