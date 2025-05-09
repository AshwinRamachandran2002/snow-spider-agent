/* Whose forum-message up-votes are closest to the 2019 average?  
   In case of a tie, return the alphabetically-first username. */

SELECT
       u."UserName"      AS "username_winner",
       u."DisplayName"   AS "display_name",
       c."vote_cnt_2019",
       c."diff_from_avg"
FROM  (
        /* 1. 2019 up-vote count per recipient & distance from the mean */
        SELECT
               "ToUserId",
               COUNT(*)                              AS "vote_cnt_2019",
               ABS( COUNT(*) - AVG(COUNT(*)) OVER () ) AS "diff_from_avg"
        FROM   "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
        WHERE  "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
        GROUP  BY "ToUserId"
      ) c
JOIN  "META_KAGGLE"."META_KAGGLE"."USERS" u
      ON u."Id" = c."ToUserId"
QUALIFY c."diff_from_avg" = MIN(c."diff_from_avg") OVER ()   -- keep the closest
ORDER  BY u."UserName"                                        -- alphabetic tie-break
FETCH 1;                                                      -- return single winner