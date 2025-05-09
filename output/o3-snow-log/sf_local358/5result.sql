SELECT
  CASE
    WHEN age BETWEEN 20 AND 29 THEN '20s'
    WHEN age BETWEEN 30 AND 39 THEN '30s'
    WHEN age BETWEEN 40 AND 49 THEN '40s'
    WHEN age BETWEEN 50 AND 59 THEN '50s'
    ELSE 'others'
  END                                              AS "AGE_CATEGORY",
  COUNT(*)                                         AS "USER_COUNT"
FROM (
       SELECT
         "user_id",
         DATEDIFF('year', TO_DATE("birth_date"), CURRENT_DATE()) AS age
       FROM LOG.LOG.MST_USERS
       WHERE "birth_date" IS NOT NULL
         AND "birth_date" <> ''
     )
GROUP BY "AGE_CATEGORY"
ORDER BY "AGE_CATEGORY";