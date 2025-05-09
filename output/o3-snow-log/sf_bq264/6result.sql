WITH filtered_users AS (
    /* users registered between 2019-01-01 and 2022-04-30 (inclusive) */
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at"/1000000) BETWEEN '2019-01-01' AND '2022-04-30'
),                                                          
age_extremes AS (         
    /* identify the youngest and oldest ages in the filtered set */
    SELECT 
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
),                            
age_counts AS (
    /* count how many users have each of those extreme ages */
    SELECT
        SUM(CASE WHEN u."age" = e.oldest_age   THEN 1 ELSE 0 END) AS oldest_count,
        SUM(CASE WHEN u."age" = e.youngest_age THEN 1 ELSE 0 END) AS youngest_count
    FROM filtered_users u
    CROSS JOIN age_extremes e
)                       
SELECT
    oldest_count,
    youngest_count,
    ABS(oldest_count - youngest_count) AS difference_in_count
FROM age_counts;