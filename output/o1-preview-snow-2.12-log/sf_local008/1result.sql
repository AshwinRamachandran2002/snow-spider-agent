(SELECT 'Games Played' AS Metric, 
        p."name_given" AS Player_Given_Name, 
        CAST(b."g" AS NUMBER(38,4)) AS Score
 FROM BASEBALL.BASEBALL.BATTING b
 JOIN BASEBALL.BASEBALL.PLAYER p ON b."player_id" = p."player_id"
 WHERE CAST(b."g" AS NUMBER) = (
     SELECT MAX(CAST(b2."g" AS NUMBER)) FROM BASEBALL.BASEBALL.BATTING b2 WHERE b2."g" IS NOT NULL
 )
 ORDER BY p."name_given" NULLS LAST
 LIMIT 1)

UNION ALL

(SELECT 'Runs' AS Metric, 
        p."name_given" AS Player_Given_Name, 
        CAST(TRY_TO_NUMBER(b."r") AS NUMBER(38,4)) AS Score
 FROM BASEBALL.BASEBALL.BATTING b
 JOIN BASEBALL.BASEBALL.PLAYER p ON b."player_id" = p."player_id"
 WHERE TRY_TO_NUMBER(b."r") = (
     SELECT MAX(TRY_TO_NUMBER(b2."r")) 
     FROM BASEBALL.BASEBALL.BATTING b2 
     WHERE TRY_TO_NUMBER(b2."r") IS NOT NULL
 )
 ORDER BY p."name_given" NULLS LAST
 LIMIT 1)

UNION ALL

(SELECT 'Hits' AS Metric, 
        p."name_given" AS Player_Given_Name, 
        CAST(TRY_TO_NUMBER(b."h") AS NUMBER(38,4)) AS Score
 FROM BASEBALL.BASEBALL.BATTING b
 JOIN BASEBALL.BASEBALL.PLAYER p ON b."player_id" = p."player_id"
 WHERE TRY_TO_NUMBER(b."h") = (
     SELECT MAX(TRY_TO_NUMBER(b2."h")) 
     FROM BASEBALL.BASEBALL.BATTING b2 
     WHERE TRY_TO_NUMBER(b2."h") IS NOT NULL
 )
 ORDER BY p."name_given" NULLS LAST
 LIMIT 1)

UNION ALL

(SELECT 'Home Runs' AS Metric, 
        p."name_given" AS Player_Given_Name, 
        CAST(TRY_TO_NUMBER(b."hr") AS NUMBER(38,4)) AS Score
 FROM BASEBALL.BASEBALL.BATTING b
 JOIN BASEBALL.BASEBALL.PLAYER p ON b."player_id" = p."player_id"
 WHERE TRY_TO_NUMBER(b."hr") = (
     SELECT MAX(TRY_TO_NUMBER(b2."hr")) 
     FROM BASEBALL.BASEBALL.BATTING b2 
     WHERE TRY_TO_NUMBER(b2."hr") IS NOT NULL
 )
 ORDER BY p."name_given" NULLS LAST
 LIMIT 1);