/* Formatted on 1/6/2023 4:15:26 PM (QP5 v5.139.911.3011) */
SET SERVEROUTPUT ON


CREATE OR REPLACE PROCEDURE delete_sequences
AS
   CURSOR seq_names
   IS
      SELECT *
        FROM user_sequences
       WHERE sequence_name LIKE UPPER ('%_sequence');
BEGIN
   FOR rec IN seq_names
   LOOP
      EXECUTE IMMEDIATE 'drop sequence ' || rec.sequence_name;
   END LOOP;
END;


CREATE OR REPLACE FUNCTION get_max_id (column_name    VARCHAR2,
                                       table_name     VARCHAR2)
   RETURN NUMBER
AS
   column_max_id   NUMBER;
BEGIN
   EXECUTE IMMEDIATE   'select max( '
                    || column_name
                    || ' ) + 1 from '
                    || table_name
      INTO column_max_id;

   RETURN column_max_id;
END;


CREATE OR REPLACE PROCEDURE create_squence (column_max_id    NUMBER,
                                            table_name       VARCHAR2)
AS
BEGIN
   EXECUTE IMMEDIATE   'create sequence '
                    || table_name
                    || '_sequence '
                    || 'start with '
                    || column_max_id
                    || ' increment by 1';
END;


CREATE OR REPLACE PROCEDURE create_trigger (column_name    VARCHAR2,
                                            table_name     VARCHAR2)
AS
BEGIN
   EXECUTE IMMEDIATE   'create or replace trigger '
                    || table_name
                    || '_trigger '
                    || 'before INSERT
                        ON '
                    || table_name
                    || ' FOR EACH ROW '
                    || 'begin 
                        :new.'
                    || column_name
                    || ' :=  '
                    || table_name
                    || '_sequence.nextval; '
                    || 'end;';
END;


DECLARE
   CURSOR pks
   IS
      SELECT t.table_name, t.column_name
        FROM user_constraints c
             JOIN user_cons_columns t
                ON c.constraint_name = t.constraint_name
                   AND LOWER (constraint_type) = 'p'
             JOIN user_tab_columns u
                ON     u.column_name = t.column_name
                   AND u.table_name = t.table_name
                   --AND u.table_name <> 'JOB_HISTORY'  -- exclude job history table
                   AND UPPER (data_type) = 'NUMBER';

   column_max_id   NUMBER;
BEGIN
   delete_sequences ();

   FOR rec IN pks
   LOOP
      column_max_id := get_max_id (rec.column_name, rec.table_name);

      IF column_max_id IS NULL
      THEN
         column_max_id := 1;
      END IF;

      create_squence (column_max_id, rec.table_name);
      create_trigger (rec.column_name, rec.table_name);

      DBMS_OUTPUT.put_line (rec.table_name || '    ' || column_max_id);
   END LOOP;
END;

SELECT * FROM user_sequences;

SHOW ERRORS