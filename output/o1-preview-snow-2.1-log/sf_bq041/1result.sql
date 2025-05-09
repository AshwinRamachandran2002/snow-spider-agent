SELECT 
  TO_CHAR(final_stats."Month", 'YYYY-MM') AS "Month",
  final_stats."New_Users",
  ROUND((final_stats."Users_Who_Asked_Questions" * 100.0) / final_stats."New_Users", 4) AS "Percentage_Asked_Questions",
  ROUND((final_stats."Users_Asked_And_Answered_Within_30_Days" * 100.0) / NULLIF(final_stats."Users_Who_Asked_Questions", 0), 4) AS "Percentage_Asked_And_Answered_Within_30_Days"
FROM (
  SELECT monthly_users."Month",
         monthly_users."New_Users",
         COALESCE(asked_questions."Users_Who_Asked_Questions", 0) AS "Users_Who_Asked_Questions",
         COALESCE(asked_and_answered."Users_Asked_And_Answered_Within_30_Days", 0) AS "Users_Asked_And_Answered_Within_30_Days"
  FROM (
    SELECT DATE_TRUNC('month', TO_TIMESTAMP_NTZ(u."creation_date", 6)) AS "Month",
           COUNT(*) AS "New_Users"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
    WHERE TO_TIMESTAMP_NTZ(u."creation_date", 6) >= '2021-01-01' 
      AND TO_TIMESTAMP_NTZ(u."creation_date", 6) < '2022-01-01'
    GROUP BY "Month"
  ) monthly_users
  LEFT JOIN (
    SELECT DATE_TRUNC('month', TO_TIMESTAMP_NTZ(u."creation_date", 6)) AS "Month",
           COUNT(DISTINCT u."id") AS "Users_Who_Asked_Questions"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
    JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
      ON u."id" = q."owner_user_id"
    WHERE TO_TIMESTAMP_NTZ(u."creation_date", 6) >= '2021-01-01' 
      AND TO_TIMESTAMP_NTZ(u."creation_date", 6) < '2022-01-01'
    GROUP BY "Month"
  ) asked_questions
    ON monthly_users."Month" = asked_questions."Month"
  LEFT JOIN (
    SELECT DATE_TRUNC('month', TO_TIMESTAMP_NTZ(u."creation_date", 6)) AS "Month",
           COUNT(DISTINCT u."id") AS "Users_Asked_And_Answered_Within_30_Days"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
    JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
      ON u."id" = q."owner_user_id"
    JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
      ON u."id" = a."owner_user_id"
    WHERE TO_TIMESTAMP_NTZ(u."creation_date", 6) >= '2021-01-01' 
      AND TO_TIMESTAMP_NTZ(u."creation_date", 6) < '2022-01-01'
      AND DATEDIFF('day', TO_TIMESTAMP_NTZ(u."creation_date", 6), TO_TIMESTAMP_NTZ(a."creation_date", 6)) <= 30
    GROUP BY "Month"
  ) asked_and_answered
    ON monthly_users."Month" = asked_and_answered."Month"
) final_stats
ORDER BY final_stats."Month";