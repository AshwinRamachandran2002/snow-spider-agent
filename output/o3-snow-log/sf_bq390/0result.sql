SELECT DISTINCT 
       dp."StudyInstanceUID"
FROM   IDC.IDC_V17.DICOM_PIVOT     dp
WHERE  dp."collection_id" = 'qin_prostate_repeatability'
  AND  dp."Modality" = 'MR'
  AND  dp."SeriesDescription" ILIKE '%T2%'
  AND  (dp."SeriesDescription" ILIKE '%AX%' 
        OR dp."SeriesDescription" ILIKE '%AXIAL%'
        OR dp."SeriesDescription" ILIKE '%TRA%'      -- common axial synonym “transverse”
       )
  /* make sure the same study also contains a SEG series whose segment is the peripheral zone */
  AND EXISTS (
        SELECT 1
        FROM   IDC.IDC_V17.SEGMENTATIONS seg
        WHERE  seg."StudyInstanceUID" = dp."StudyInstanceUID"
          AND  seg."SegmentedPropertyType":"CodeMeaning"::string ILIKE '%peripheral%'
      )
ORDER BY dp."StudyInstanceUID";