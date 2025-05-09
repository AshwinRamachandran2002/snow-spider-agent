/*  Monthly add-to-cart & purchase conversion rates
    ( % of product–detail page-views ) – Jan-Mar 2017 */

WITH sessions AS (       ------------------------------------------------------
    /* ---------- 2017-01 ---------------------------------------------------- */
    SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170102
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170103
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170104
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170105
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170106
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170107
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170108
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170109
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170110
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170111
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170112
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170113
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170114
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170115
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170116
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170117
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170118
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170119
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170120
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170121
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170122
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170123
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170124
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170125
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170126
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170127
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170128
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170129
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170130
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170131
    /* ---------- 2017-02 ---------------------------------------------------- */
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228
    /* ---------- 2017-03 ---------------------------------------------------- */
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170301
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170302
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170303
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170304
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170305
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170306
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170307
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170308
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170309
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170310
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170311
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170312
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170313
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170314
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170315
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170316
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170317
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170318
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170319
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170320
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170321
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170322
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170323
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170324
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170325
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170326
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170327
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170328
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170329
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170330
    UNION ALL SELECT "date","fullVisitorId","visitId","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170331
)   ---------------------------------------------------------------------------

/* -------------------------------------------------------------------------- */
, hits_lvl AS (
    SELECT
        TO_CHAR(TO_DATE(s."date",'YYYYMMDD'),'YYYY-MM')              AS "month",
        s."fullVisitorId"                                            AS "visitor_id",
        s."visitId"                                                  AS "visit_id",
        hit.value:"hitNumber"::NUMBER                                AS "hit_num",
        hit.value:"eCommerceAction":"action_type"::NUMBER            AS "action_type",
        prd.value:"isImpression"::BOOLEAN                            AS "is_impression"
    FROM sessions  AS s
         ,LATERAL FLATTEN(input => s."hits")                         AS hit
         ,LATERAL FLATTEN(input => hit.value:"product", outer => TRUE) AS prd
    WHERE hit.value:"eCommerceAction":"action_type"::NUMBER IN (2,3,6)
)

/* keep one row per hit & drop product-impression rows */
, per_hit AS (
    SELECT DISTINCT
           "month",
           "action_type",
           CONCAT("visitor_id",'-',"visit_id",'-',"hit_num") AS "hit_id"
    FROM hits_lvl
    WHERE "is_impression" IS NULL OR "is_impression" = FALSE
)

/* aggregate & compute rates */
, agg AS (
    SELECT
        "month",
        SUM(CASE WHEN "action_type" = 2 THEN 1 ELSE 0 END) AS product_detail_views,
        SUM(CASE WHEN "action_type" = 3 THEN 1 ELSE 0 END) AS add_to_cart_hits,
        SUM(CASE WHEN "action_type" = 6 THEN 1 ELSE 0 END) AS purchase_hits
    FROM per_hit
    GROUP BY "month"
)

SELECT
    "month",
    ROUND(add_to_cart_hits * 100.0 / product_detail_views , 4) AS add_to_cart_conversion_rate_pct,
    ROUND(purchase_hits   * 100.0 / product_detail_views , 4) AS purchase_conversion_rate_pct
FROM agg
ORDER BY "month";