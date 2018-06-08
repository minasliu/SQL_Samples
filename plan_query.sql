/*****************************************************************************/
/*     File Name     : plan_query    .sql                                    */
/*     Description   : Pulls Drive data for PlanJust spreadsheet to dev plan */
/*     Input tables  : 	date_cd_v                                            */
/*			cust_req_date_cd_v                                   */
/*			cust_book_keycomp_v                                  */
/*			keycomp_desc_item_cd_v                               */
/*			mkt_item_cd_v                                        */
/*			kc_qtr_data                                          */
/*     Output file   :  /home/minal/HardDrives/Plan/TotalCRDBooks.csv        */
/*			/home/minal/HardDrives/Plan/OtherCRDBooks.csv        */
/*			/home/minal/HardDrives/Plan/OtherFill.csv            */
/*****************************************************************************/

SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET VERIFY ON;
SET HEADING OFF;
SET HEADING ON;

VARIABLE currqtr CHAR(6);
VARIABLE prevqtr CHAR(6);

BEGIN
    SELECT fiscal_year_qtr
    INTO   :currqtr
    FROM   date_cd_v
    WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY');

    SELECT fiscal_year_qtr
    INTO   :prevqtr
    FROM   date_cd_v
    WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate-91,'MM/DD/YYYY');
  END;
/


SPOOL /home/minal/HardDrives/Plan/TotalCRDBooks.csv
SELECT TO_CHAR(sysdate,'MM-DD-YYYY HH:MI:SS') FROM dual;

PROMPT Data up to week:
SELECT 	WEEK_OF_FISCAL_QTR || ',' ||
	calendar_date || ',,,,,,,,,,,,,,,,,,,,,,,,,,,'
FROM   date_cd_v
WHERE  TO_CHAR((calendar_date),'MM/DD/YYYY') = TO_CHAR((sysdate-7),'MM/DD/YYYY');

CREATE TABLE raw_data AS
SELECT	c.kc_desc_descr kc_desc, 
	a.crd_fiscal_year_qtr fq,
	a.crd_week_of_fiscal_qtr fw,
	'    ' qtr_wk,
	SUM(b.book_keycomp_qty) book_qty
FROM	cust_req_date_cd_v a,  
	cust_book_keycomp_v b,
	keycomp_desc_item_cd_v c, 
	mkt_item_cd_v m
WHERE 	a.crd_date_pk = b.crd_date_pk
AND   	b.kc_desc_item_pk = c.kc_desc_item_pk
AND   	b.mkt_item_pk = m.mkt_item_pk
AND   	(a.crd_fiscal_year_qtr =
		(SELECT fiscal_year_qtr
    		FROM   date_cd_v
    		WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
OR	a.crd_fiscal_year_qtr =
		(SELECT fiscal_year_qtr
    		FROM   date_cd_v
    		WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate-91,'MM/DD/YYYY')))
AND   c.kc_desc_type IN ('STORAGE_HD') 
AND	m.mkt_item_number !=('R*')
GROUP BY c.kc_desc_descr, 
	a.crd_fiscal_year_qtr,
	a.crd_week_of_fiscal_qtr
ORDER BY c.kc_desc_descr, 
	a.crd_fiscal_year_qtr,
	a.crd_week_of_fiscal_qtr;

UPDATE raw_data
SET qtr_wk = 'CQ'||fw
WHERE fq=:currqtr;

UPDATE raw_data
SET qtr_wk = 'PQ'||fw
WHERE fq=:prevqtr;

CREATE TABLE temp_table_ML AS
SELECT 	kc_desc,
	decode(qtr_wk, 'PQ1 ',book_qty,0) PQ1,
	decode(qtr_wk, 'PQ2 ',book_qty,0) PQ2,
	decode(qtr_wk, 'PQ3 ',book_qty,0) PQ3,
	decode(qtr_wk, 'PQ4 ',book_qty,0) PQ4,
	decode(qtr_wk, 'PQ5 ',book_qty,0) PQ5,
	decode(qtr_wk, 'PQ6 ',book_qty,0) PQ6,
	decode(qtr_wk, 'PQ7 ',book_qty,0) PQ7,
	decode(qtr_wk, 'PQ8 ',book_qty,0) PQ8,
	decode(qtr_wk, 'PQ9 ',book_qty,0) PQ9,
	decode(qtr_wk, 'PQ10',book_qty,0) PQ10,
	decode(qtr_wk, 'PQ11',book_qty,0) PQ11,
	decode(qtr_wk, 'PQ12',book_qty,0) PQ12,
	decode(qtr_wk, 'PQ13',book_qty,0) PQ13,
	decode(qtr_wk, 'CQ1 ',book_qty,0) CQ1,
	decode(qtr_wk, 'CQ2 ',book_qty,0) CQ2,
	decode(qtr_wk, 'CQ3 ',book_qty,0) CQ3,
	decode(qtr_wk, 'CQ4 ',book_qty,0) CQ4,
	decode(qtr_wk, 'CQ5 ',book_qty,0) CQ5,
	decode(qtr_wk, 'CQ6 ',book_qty,0) CQ6,
	decode(qtr_wk, 'CQ7 ',book_qty,0) CQ7,
	decode(qtr_wk, 'CQ8 ',book_qty,0) CQ8,
	decode(qtr_wk, 'CQ9 ',book_qty,0) CQ9,
	decode(qtr_wk, 'CQ10',book_qty,0) CQ10,
	decode(qtr_wk, 'CQ11',book_qty,0) CQ11,
	decode(qtr_wk, 'CQ12',book_qty,0) CQ12,
	decode(qtr_wk, 'CQ13',book_qty,0) CQ13
FROM	raw_data
GROUP BY kc_desc, qtr_wk, book_qty;

PROMPT Total Weekly CRD Bookings;
select to_char(sysdate,'MM-DD-YYYY HH:MI:SS') from dual;
PROMPT	kc_desc,PQ1,PQ2,PQ3,PQ4,PQ5,PQ6,PQ7,PQ8,PQ9,PQ10,PQ11,PQ12,PQ13,CQ1,CQ2,CQ3,CQ4,CQ5,CQ6,CQ7,CQ8,CQ9,CQ10,CQ11,CQ12,CQ13
SELECT 	kc_desc || ',' ||
	sum(PQ1) || ',' ||
	sum(PQ2) || ',' ||
	sum(PQ3) || ',' ||
	sum(PQ4) || ',' ||
	sum(PQ5) || ',' ||
	sum(PQ6) || ',' ||
	sum(PQ7) || ',' ||
	sum(PQ8) || ',' ||
	sum(PQ9) || ',' ||
	sum(PQ10) || ',' ||
	sum(PQ11) || ',' ||
	sum(PQ12) || ',' ||
	sum(PQ13) || ',' ||
	sum(CQ1) || ',' ||
	sum(CQ2) || ',' ||
	sum(CQ3) || ',' ||
	sum(CQ4) || ',' ||
	sum(CQ5) || ',' ||
	sum(CQ6) || ',' ||
	sum(CQ7) || ',' ||
	sum(CQ8) || ',' ||
	sum(CQ9) || ',' ||
	sum(CQ10) || ',' ||
	sum(CQ11) || ',' ||
	sum(CQ12) || ',' ||
	sum(CQ13)
FROM temp_table_ML
GROUP BY kc_desc
ORDER BY kc_desc;

SPOOL OFF;
DROP TABLE raw_data;
DROP TABLE temp_table_ML;


SPOOL /home/minal/HardDrives/Plan/OtherCRDBooks.csv
CREATE TABLE raw_data AS
SELECT	c.kc_desc_descr kc_desc, 
	a.crd_fiscal_year_qtr fq,
	a.crd_week_of_fiscal_qtr fw,
	'    ' qtr_wk,
	SUM(b.book_keycomp_qty) book_qty
FROM	cust_req_date_cd_v a,  
	cust_book_keycomp_v b,
	keycomp_desc_item_cd_v c, 
	platform_item_cd_v d,
	mkt_item_cd_v m
WHERE 	a.crd_date_pk = b.crd_date_pk
AND   	b.kc_desc_item_pk = c.kc_desc_item_pk
AND	b.platform_item_pk = d.platform_item_pk
AND   	b.mkt_item_pk = m.mkt_item_pk
AND   	(a.crd_fiscal_year_qtr =
		(SELECT fiscal_year_qtr
    		FROM   date_cd_v
    		WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
OR	a.crd_fiscal_year_qtr =
		(SELECT fiscal_year_qtr
    		FROM   date_cd_v
    		WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate-91,'MM/DD/YYYY')))
AND   	c.kc_desc_type IN ('STORAGE_HD') 
AND	m.mkt_item_number !=('R*')
AND	d.platform_name = 'OTHER'
GROUP BY c.kc_desc_descr, 
	a.crd_fiscal_year_qtr,
	a.crd_week_of_fiscal_qtr
ORDER BY c.kc_desc_descr, 
	a.crd_fiscal_year_qtr,
	a.crd_week_of_fiscal_qtr;

UPDATE raw_data
SET qtr_wk = 'CQ'||fw
WHERE fq=:currqtr
;
UPDATE raw_data
SET qtr_wk = 'PQ'||fw
WHERE fq=:prevqtr;

CREATE TABLE temp_table_ML AS
SELECT 	kc_desc,
	decode(qtr_wk, 'PQ1 ',book_qty,0) PQ1,
	decode(qtr_wk, 'PQ2 ',book_qty,0) PQ2,
	decode(qtr_wk, 'PQ3 ',book_qty,0) PQ3,
	decode(qtr_wk, 'PQ4 ',book_qty,0) PQ4,
	decode(qtr_wk, 'PQ5 ',book_qty,0) PQ5,
	decode(qtr_wk, 'PQ6 ',book_qty,0) PQ6,
	decode(qtr_wk, 'PQ7 ',book_qty,0) PQ7,
	decode(qtr_wk, 'PQ8 ',book_qty,0) PQ8,
	decode(qtr_wk, 'PQ9 ',book_qty,0) PQ9,
	decode(qtr_wk, 'PQ10',book_qty,0) PQ10,
	decode(qtr_wk, 'PQ11',book_qty,0) PQ11,
	decode(qtr_wk, 'PQ12',book_qty,0) PQ12,
	decode(qtr_wk, 'PQ13',book_qty,0) PQ13,
	decode(qtr_wk, 'CQ1 ',book_qty,0) CQ1,
	decode(qtr_wk, 'CQ2 ',book_qty,0) CQ2,
	decode(qtr_wk, 'CQ3 ',book_qty,0) CQ3,
	decode(qtr_wk, 'CQ4 ',book_qty,0) CQ4,
	decode(qtr_wk, 'CQ5 ',book_qty,0) CQ5,
	decode(qtr_wk, 'CQ6 ',book_qty,0) CQ6,
	decode(qtr_wk, 'CQ7 ',book_qty,0) CQ7,
	decode(qtr_wk, 'CQ8 ',book_qty,0) CQ8,
	decode(qtr_wk, 'CQ9 ',book_qty,0) CQ9,
	decode(qtr_wk, 'CQ10',book_qty,0) CQ10,
	decode(qtr_wk, 'CQ11',book_qty,0) CQ11,
	decode(qtr_wk, 'CQ12',book_qty,0) CQ12,
	decode(qtr_wk, 'CQ13',book_qty,0) CQ13
FROM	raw_data
GROUP BY kc_desc, qtr_wk, book_qty;

PROMPT	kc_desc,PQ1,PQ2,PQ3,PQ4,PQ5,PQ6,PQ7,PQ8,PQ9,PQ10,PQ11,PQ12,PQ13,CQ1,CQ2,CQ3,CQ4,CQ5,CQ6,CQ7,CQ8,CQ9,CQ10,CQ11,CQ12,CQ13
SELECT 	kc_desc || ',' ||
	sum(PQ1) || ',' ||
	sum(PQ2) || ',' ||
	sum(PQ3) || ',' ||
	sum(PQ4) || ',' ||
	sum(PQ5) || ',' ||
	sum(PQ6) || ',' ||
	sum(PQ7) || ',' ||
	sum(PQ8) || ',' ||
	sum(PQ9) || ',' ||
	sum(PQ10) || ',' ||
	sum(PQ11) || ',' ||
	sum(PQ12) || ',' ||
	sum(PQ13) || ',' ||
	sum(CQ1) || ',' ||
	sum(CQ2) || ',' ||
	sum(CQ3) || ',' ||
	sum(CQ4) || ',' ||
	sum(CQ5) || ',' ||
	sum(CQ6) || ',' ||
	sum(CQ7) || ',' ||
	sum(CQ8) || ',' ||
	sum(CQ9) || ',' ||
	sum(CQ10) || ',' ||
	sum(CQ11) || ',' ||
	sum(CQ12) || ',' ||
	sum(CQ13)
FROM temp_table_ML
GROUP BY kc_desc
ORDER BY kc_desc;
SPOOL OFF;

SPOOL /home/minal/HardDrives/Plan/OtherFill.csv
PROMPT Other Weekly Fill
select to_char(sysdate,'MM-DD-YYYY HH:MI:SS') from dual;
PROMPT kc_desc,fill,
SELECT 	kc_desc || ',' ||
	sum(fill) || ','
FROM 	kc_qtr_data
WHERE	kc_type= 'STORAGE_HD'
AND	fiscal_qtr=
		(SELECT fiscal_year_qtr
    		FROM   date_cd_v
    		WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
AND	marketing_part_no !='R*'
GROUP BY kc_desc
ORDER BY kc_desc;

SPOOL OFF;

COMMIT;
DROP TABLE raw_data;
DROP TABLE temp_table_ML;
EXIT;
