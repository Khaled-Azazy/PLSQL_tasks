/* Formatted on 1/3/2023 8:18:50 PM (QP5 v5.139.911.3011) */
set serveroutput on

CREATE OR REPLACE FUNCTION HR.calc_nofmonths (start_date DATE, end_date DATE)
   RETURN NUMBER
AS
   n_of_months   NUMBER (10, 2);
BEGIN
   n_of_months := extract (year from end_date) - extract (year from start_date);
   RETURN n_of_months*12;
END;


CREATE OR REPLACE FUNCTION HR.calc_payemnt (total_fees      NUMBER,
                                         deposit_fees    NUMBER)
   RETURN NUMBER
AS
   payment   NUMBER (10, 2);
BEGIN
   payment := (total_fees - deposit_fees);
   RETURN payment;
END;

CREATE OR REPLACE PROCEDURE HR.fill_installments_paid (payment         NUMBER,
                                                    n_of_months     NUMBER,
                                                    payment_type    VARCHAR2,
                                                    contract_id     NUMBER,
                                                    start_date      DATE)
AS
   add_month     NUMBER;
   iterations    NUMBER;
   cur_date      DATE;
   one_payment   NUMBER (10, 2);
   summ          NUMBER (10, 2) := 0; -- sum all
BEGIN
   cur_date := start_date;

   CASE payment_type
      WHEN 'ANNUAL'
      THEN
         add_month := 12;
      WHEN 'QUARTER'
      THEN
         add_month := 3;
      WHEN 'MONTHLY'
      THEN
         add_month := 1;
      WHEN 'HALF_ANNUAL'
      THEN
         add_month := 6;
   END CASE;

   iterations := n_of_months / add_month;
   one_payment := payment / iterations;

   FOR i IN 1 .. iterations
   LOOP
      --summ := summ + one_payment ;
      INSERT INTO installments_paid (contract_id,
                                     installment_amount,
                                     installment_date,
                                     installment_id)
           VALUES (contract_id,
                   one_payment,
                   cur_date,
                   installment_seq.NEXTVAL);

      cur_date := ADD_MONTHS (cur_date, add_month);
      DBMS_OUTPUT.
      put_line (
         cur_date || '    ' || ROUND (one_payment, 2) || '   ' || n_of_months);
   END LOOP;
--DBMS_OUTPUT.put_line(summ);
END;



DECLARE
   CURSOR contracts_cur
   IS
      SELECT * FROM contracts;

   months    NUMBER (5);
   payment   NUMBER (10, 2);
BEGIN
   FOR rec IN contracts_cur
   LOOP
      months := calc_nofmonths (rec.contract_startdate, rec.contract_enddate);
      payment :=
         calc_payemnt (rec.contract_total_fees,
                       NVL (rec.contract_deposit_fees, 0));
      fill_installments_paid (payment,
                              months,
                              rec.contract_payment_type,
                              rec.contract_id,
                              rec.contract_startdate);
   END LOOP;
END;