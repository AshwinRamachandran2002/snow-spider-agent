WITH target_patents AS (   -- U.S. patents filed 1‑Jan‑2014 – 1‑Feb‑2014 in chemistry/biology/medical CPC
    SELECT DISTINCT
           p."id"        AS patent_id,
           p."title"     AS title,
           p."abstract"  AS abstract,
           p."date"      AS pub_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a  ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c  ON c."patent_id" = p."id"
    WHERE a."country" = 'US'
      AND a."date" BETWEEN '2014-01-01' AND '2014-02-01'
      AND (
             (c."subsection_id" BETWEEN 'C05' AND 'C13')
          OR c."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                              'B01F','B01J','B81B','B82B','B82Y',
                              'G01N','G16H')
          )
),
/* backward citations: patents the current patent cites,
   limited to citations where cited‑patent date < current patent’s filing date */
backward_cte AS (
    SELECT
           t.patent_id,
           COUNT(DISTINCT u."citation_id") AS backward_citations
    FROM   target_patents                           t
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
           ON u."patent_id" = t.patent_id
    JOIN   PATENTSVIEW.PATENTSVIEW.APPLICATION      ap
           ON ap."patent_id" = t.patent_id
    WHERE  u."date" < ap."date"
    GROUP  BY t.patent_id
),
/* forward citations: later patents that cite the current patent
   within 5 years after its publication date */
forward_cte AS (
    SELECT
           t.patent_id,
           COUNT(DISTINCT u."patent_id") AS forward_citations_5yr
    FROM   target_patents                           t
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
           ON u."citation_id" = t.patent_id
    JOIN   PATENTSVIEW.PATENTSVIEW.PATENT  fp       -- citing patent
           ON fp."id" = u."patent_id"
    WHERE  fp."date" >  t.pub_date                    -- after publication
      AND  fp."date" <= DATEADD(year, 5, t.pub_date)  -- within 5‑year window
    GROUP  BY t.patent_id
)

SELECT
       t.patent_id,
       t.title,
       t.abstract,
       t.pub_date                                AS publication_date,
       COALESCE(b.backward_citations, 0)         AS num_backward_citations,
       COALESCE(f.forward_citations_5yr, 0)      AS num_forward_citations_5yr
FROM   target_patents t
LEFT  JOIN backward_cte b ON b.patent_id = t.patent_id
LEFT  JOIN forward_cte  f ON f.patent_id = t.patent_id
ORDER BY t.pub_date,
         t.patent_id;