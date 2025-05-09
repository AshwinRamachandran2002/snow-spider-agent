WITH seg AS (
    /* kidney‑cancer (TCGA‑KIRC) allelic segments on chr1
       classify each segment by copy‑number severity            */
    SELECT 
        (("start_pos" + "end_pos") / 2)::NUMBER          AS mid_pos,
        CASE 
            WHEN "copy_number" > 3 THEN 'Amplification'
            WHEN "copy_number" = 3 THEN 'Gain'
            WHEN "copy_number" = 1 THEN 'HetDeletion'
        END                                             AS category
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
      AND "chromosome" = 'chr1'
      AND "copy_number" IS NOT NULL
      AND ("copy_number" > 3 OR "copy_number" IN (3,1))
),       
seg_band AS (
    /* map every segment midpoint to its hg38 cytoband on chr1  */
    SELECT 
        cb."cytoband_name",
        s.category
    FROM seg             s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 cb
      ON cb."chromosome" = 'chr1'
     AND s.mid_pos BETWEEN cb."hg38_start" AND cb."hg38_stop"
),        
band_counts AS (
    /* how many segments of each class fall in each cytoband    */
    SELECT 
        "cytoband_name",
        category,
        COUNT(*)                     AS seg_cnt
    FROM seg_band
    GROUP BY "cytoband_name", category
),        
ranked AS (
    /* rank cytobands by frequency inside each alteration class */
    SELECT 
        "cytoband_name",
        category,
        seg_cnt,
        RANK() OVER (PARTITION BY category 
                     ORDER BY seg_cnt DESC NULLS LAST) AS rnk
    FROM band_counts
),        
pivoted AS (
    /* collect the three ranks side‑by‑side for each cytoband   */
    SELECT
        "cytoband_name",
        MAX(CASE WHEN category = 'Amplification' THEN rnk END) AS rank_amp,
        MAX(CASE WHEN category = 'Gain'          THEN rnk END) AS rank_gain,
        MAX(CASE WHEN category = 'HetDeletion'   THEN rnk END) AS rank_het
    FROM ranked
    GROUP BY "cytoband_name"
)
SELECT 
    "cytoband_name"
FROM pivoted
WHERE rank_amp  <= 11
  AND rank_gain <= 11
  AND rank_het  <= 11
ORDER BY "cytoband_name";