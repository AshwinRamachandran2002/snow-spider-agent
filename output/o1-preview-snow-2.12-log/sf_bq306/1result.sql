SELECT
  T.VALUE::STRING AS "Tag",
  SUM(CASE WHEN V."vote_type_id" = 2 THEN 10 ELSE 0 END) +
  SUM(CASE WHEN V."vote_type_id" = 1 THEN 15 ELSE 0 END) AS "Total_Score"
FROM
  "STACKOVERFLOW"."STACKOVERFLOW"."VOTES" V
JOIN
  "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" A
    ON V."post_id" = A."id"
JOIN
  "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" Q
    ON A."parent_id" = Q."id",
LATERAL FLATTEN(
  INPUT => SPLIT(
    REPLACE(
      REPLACE(
        REPLACE(Q."tags", '><', ','),
        '<', ''
      ),
      '>', ''
    ),
    ','
  )
) T
WHERE
  A."owner_user_id" = 1908967
  AND TO_TIMESTAMP_NTZ(A."creation_date" / 1e6) < TO_TIMESTAMP_NTZ('2018-06-07', 'YYYY-MM-DD')
  AND V."vote_type_id" IN (1, 2)
GROUP BY
  T.VALUE::STRING
ORDER BY
  "Total_Score" DESC NULLS LAST
LIMIT 10;