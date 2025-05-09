WITH combined AS (
  SELECT "gender", 'Youngest' AS "Age_Type", COUNT(*) AS "Total_Number", 1 AS "Age_Order"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U1
  WHERE "created_at" BETWEEN 1546300800000000 AND 1651276799000000
    AND "age" = (
      SELECT MIN("age")
      FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U2
      WHERE U2."gender" = U1."gender"
        AND U2."created_at" BETWEEN 1546300800000000 AND 1651276799000000
    )
  GROUP BY "gender"

  UNION ALL

  SELECT "gender", 'Oldest' AS "Age_Type", COUNT(*) AS "Total_Number", 2 AS "Age_Order"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U1
  WHERE "created_at" BETWEEN 1546300800000000 AND 1651276799000000
    AND "age" = (
      SELECT MAX("age")
      FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U2
      WHERE U2."gender" = U1."gender"
        AND U2."created_at" BETWEEN 1546300800000000 AND 1651276799000000
    )
  GROUP BY "gender"
)
SELECT "gender", "Age_Type", "Total_Number"
FROM combined
ORDER BY "Age_Order", "gender";