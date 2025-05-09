SELECT 
  "Years_of_membership",
  ROUND(AVG("reputation"), 4) AS "Average_reputation",
  ROUND(AVG("badge_count"), 4) AS "Average_number_of_badges"
FROM (
  SELECT
    u."id", 
    u."reputation",
    FLOOR(DATEDIFF('year', TO_TIMESTAMP(u."creation_date" / 1e6), '2021-10-01')) AS "Years_of_membership",
    COUNT(b."id") AS "badge_count"
  FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
  LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.BADGES b ON u."id" = b."user_id"
  WHERE TO_TIMESTAMP(u."creation_date" / 1e6) <= '2021-10-01'
  GROUP BY u."id", u."reputation", u."creation_date"
) AS user_stats
GROUP BY "Years_of_membership"
ORDER BY "Years_of_membership" ASC;