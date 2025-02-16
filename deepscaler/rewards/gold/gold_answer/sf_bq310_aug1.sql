-- Task: Find the titles of up to 100 questions related to Android development on StackOverflow, across specified tags such as 'android-layout', 'android-activity', 'android-intent', and others.

SELECT "title"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS",
     LATERAL FLATTEN(input => SPLIT("tags", '|')) AS t
WHERE t.value IN ('android', 'android-layout', 'android-activity', 'android-intent')
LIMIT 100;