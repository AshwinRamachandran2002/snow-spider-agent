SELECT DISTINCT
       s."StudyInstanceUID"
FROM   IDC.IDC_V17."SEGMENTATIONS"  s
JOIN   IDC.IDC_V17."DICOM_PIVOT"    p
       ON p."SeriesInstanceUID" = s."SeriesInstanceUID"
WHERE  p."collection_id" = 'qin_prostate_repeatability'
  AND  s."SegmentedPropertyType":"CodeMeaning"::STRING ILIKE '%peripheral%'
  AND  EXISTS (
        SELECT 1
        FROM   IDC.IDC_V17."DICOM_PIVOT" p2
        WHERE  p2."StudyInstanceUID" = s."StudyInstanceUID"
          AND  p2."collection_id"    = 'qin_prostate_repeatability'
          AND  p2."Modality"         = 'MR'
          AND  (p2."SeriesDescription" ILIKE '%t2%' 
                OR p2."ImageType"     ILIKE '%t2%')
          AND  (p2."SeriesDescription" ILIKE '%ax%' 
                OR p2."SeriesDescription" ILIKE '%axi%' 
                OR p2."SeriesDescription" ILIKE '%tra%' 
                OR p2."ImageType"     ILIKE '%ax%' 
                OR p2."ImageType"     ILIKE '%tra%')
      )
ORDER BY
       s."StudyInstanceUID";