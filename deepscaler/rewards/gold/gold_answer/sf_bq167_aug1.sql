-- Task: For each pair of users, find the total number of distinct upvotes one has given to the other. Present the usernames of both users and the total distinct upvotes, sorting by the highest upvote count, and show only the top 100 results.
SELECT
  ToUsers."UserName" AS "ToUserName",
  FromUsers."UserName" AS "FromUserName",
  COUNT(DISTINCT "ForumMessageVotes"."Id") AS "UpvoteCount"
FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES AS "ForumMessageVotes"
INNER JOIN META_KAGGLE.META_KAGGLE.USERS AS FromUsers
  ON FromUsers."Id" = "ForumMessageVotes"."FromUserId"
INNER JOIN META_KAGGLE.META_KAGGLE.USERS AS ToUsers
  ON ToUsers."Id" = "ForumMessageVotes"."ToUserId"
GROUP BY
  ToUsers."UserName",
  FromUsers."UserName"
ORDER BY
  "UpvoteCount" DESC
LIMIT 100;