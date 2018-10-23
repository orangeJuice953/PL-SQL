SET SERVEROUTPUT ON SIZE UNLIMITED
@/home/student/Data/cit325/oracle/lib/cleanup_oracle.sql
@/home/student/Data/cit325/oracle/lib/Oracle12cPLSQLCode/Introduction/create_video_store.sql

SPOOL apply_plsql_lab7_Tang.log

-- Step0 Fix DBA number.
SELECT system_user_id
,      system_user_name
FROM   system_user
WHERE  system_user_name = 'DBA';

-- Ensure your iterative test cases all start at the same point
UPDATE system_user
SET    system_user_name = 'DBA'
WHERE  system_user_name LIKE 'DBA%';

-- A small anonymous block PL/SQL program lets you fix this mistake:
DECLARE
  /* Create a local counter variable. */
  lv_counter  NUMBER := 2;

  /* Create a collection of two-character strings. */
  TYPE numbers IS TABLE OF NUMBER;

  /* Create a variable of the roman_numbers collection. */
  lv_numbers  NUMBERS := numbers(1,2,3,4);

BEGIN
  /* Update the system_user names to make them unique. */
  FOR i IN 1..lv_numbers.COUNT LOOP
    /* Update the system_user table. */
    UPDATE system_user
    SET    system_user_name = system_user_name || ' ' || lv_numbers(i)
    WHERE  system_user_id = lv_counter;

    /* Increment the counter. */
    lv_counter := lv_counter + 1;
  END LOOP;
END;
/

-- Verification updated four rows.
SELECT system_user_id
,      system_user_name
FROM   system_user
WHERE  system_user_name LIKE 'DBA%';

-- Drop existing objects
BEGIN
  FOR i IN (SELECT uo.object_type
            ,      uo.object_name
            FROM   user_objects uo
            WHERE  uo.object_name = 'INSERT_CONTACT') LOOP
    EXECUTE IMMEDIATE 'DROP ' || i.object_type || ' ' || i.object_name;
  END LOOP;
END;
/

-- Step1 Create an insert_contact procedure.
CREATE OR REPLACE PROCEDURE insert_contact
( pv_first_name          VARCHAR2
, pv_middle_name         VARCHAR2
, pv_last_name           VARCHAR2
, pv_contact_type        VARCHAR2
, pv_account_number      VARCHAR2
, pv_member_type         VARCHAR2
, pv_credit_card_number  VARCHAR2
, pv_credit_card_type    VARCHAR2
, pv_city                VARCHAR2
, pv_state_province      VARCHAR2
, pv_postal_code         VARCHAR2
, pv_address_type        VARCHAR2
, pv_country_code        VARCHAR2
, pv_area_code           VARCHAR2
, pv_telephone_number    VARCHAR2
, pv_telephone_type      VARCHAR2
, pv_user_name           VARCHAR2 ) IS

  -- Declare local constants.
  lv_creation_date     DATE := SYSDATE;

  -- Declare a who-audit ID variable.
  lv_created_by        NUMBER;

  -- Declare type variables.
  lv_member_type       NUMBER;
  lv_credit_card_type  NUMBER;
  lv_contact_type      NUMBER;
  lv_address_type      NUMBER;
  lv_telephone_type    NUMBER;

  -- Declare a local cursor.
  CURSOR get_lookup_type
  ( cv_table_name    VARCHAR2
  , cv_column_name   VARCHAR2
  , cv_type_name     VARCHAR2 ) IS
    SELECT common_lookup_id
    FROM   common_lookup
    WHERE  common_lookup_table = cv_table_name
    AND    common_lookup_column = cv_column_name
    AND    common_lookup_type = cv_type_name;

BEGIN
  /* Get the member_type ID value. */
  FOR i IN get_lookup_type('MEMBER','MEMBER_TYPE',pv_member_type) LOOP
    lv_member_type := i.common_lookup_id;
  END LOOP;

  /* Get the credit_card_type ID value. */
  FOR i IN get_lookup_type('MEMBER','CREDIT_CARD_TYPE',pv_credit_card_type) LOOP
    lv_credit_card_type := i.common_lookup_id;
  END LOOP;

  /* Get the contact_type ID value. */
  FOR i IN get_lookup_type('CONTACT','CONTACT_TYPE',pv_contact_type) LOOP
    lv_contact_type := i.common_lookup_id;
  END LOOP;

  /* Get the address_type ID value. */
  FOR i IN get_lookup_type('ADDRESS','ADDRESS_TYPE',pv_address_type) LOOP
    lv_address_type := i.common_lookup_id;
  END LOOP;

  /* Get the telephone_type ID value. */
  FOR i IN get_lookup_type('TELEPHONE','TELEPHONE_TYPE',pv_telephone_type) LOOP
    lv_telephone_type := i.common_lookup_id;
  END LOOP;

  -- Get the system user ID value.
  SELECT system_user_id
  INTO   lv_created_by
  FROM   system_user
  WHERE  system_user_name = pv_user_name;

  -- Set save point.
  SAVEPOINT start_point;

  -- Insert into member table.
  INSERT INTO member
  ( member_id
  , member_type
  , account_number
  , credit_card_number
  , credit_card_type
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date )
  VALUES
  ( member_s1.NEXTVAL
  , lv_member_type
  , pv_account_number
  , pv_credit_card_number
  , lv_credit_card_type
  , lv_created_by
  , lv_creation_date
  , lv_created_by
  , lv_creation_date);

  -- Insert into contact table.
  INSERT INTO contact
  ( contact_id
  , member_id
  , contact_type
  , first_name
  , middle_name
  , last_name
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date )
  VALUES
  ( contact_s1.NEXTVAL
  , member_s1.CURRVAL
  , lv_contact_type
  , pv_first_name
  , pv_middle_name
  , pv_last_name
  , lv_created_by
  , lv_creation_date
  , lv_created_by
  , lv_creation_date);

  -- Insert into ADDRESS table.
  INSERT INTO address
  ( address_id
  , contact_id
  , address_type
  , city
  , state_province
  , postal_code
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date )
  VALUES
  ( address_s1.NEXTVAL
  , contact_s1.CURRVAL
  , lv_address_type
  , pv_city
  , pv_state_province
  , pv_postal_code
  , lv_created_by
  , lv_creation_date
  , lv_created_by
  , lv_creation_date);

  -- Insert into telephone table.
  INSERT INTO telephone
  ( telephone_id
  , contact_id
  , address_id
  , telephone_type
  , country_code
  , area_code
  , telephone_number
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date )
  VALUES
  ( telephone_s1.NEXTVAL
  , contact_s1.CURRVAL
  , address_s1.CURRVAL
  , lv_telephone_type
  , pv_country_code
  , pv_area_code
  , pv_telephone_number
  , lv_created_by
  , lv_creation_date
  , lv_created_by
  , lv_creation_date);

  -- Commit the writes to all four tables.
  COMMIT;

EXCEPTION
  -- Catch all errors.
  WHEN OTHERS THEN
    ROLLBACK TO start_point;
END insert_contact;
/

--  Step1 insert_contact value.
BEGIN
insert_contact

( 'Charles'
, 'Francis'
, 'Xavier'
, 'CUSTOMER'
, 'SLC-000008'
, 'INDIVIDUAL'
, '7777-6666-5555-4444'
, 'DISCOVER_CARD'
, 'Milbridge'
, 'Maine'
, '04658'
, 'HOME'
, '001'
, '207'
, '111-1234'
, 'HOME'
, 'DBA 2');
END;
/

-- Test case step1, insert_contact table.
DESC insert_contact

-- Verification for step1.
COL full_name      FORMAT A24
COL account_number FORMAT A10 HEADING "ACCOUNT|NUMBER"
COL address        FORMAT A22
COL telephone      FORMAT A14

SELECT c.first_name
||     CASE
         WHEN c.middle_name IS NOT NULL THEN ' '||c.middle_name||' ' ELSE ' '
       END
||     c.last_name AS full_name
,      m.account_number
,      a.city || ', ' || a.state_province AS address
,      '(' || t.area_code || ') ' || t.telephone_number AS telephone
FROM   member m INNER JOIN contact c
ON     m.member_id = c.member_id INNER JOIN address a
ON     c.contact_id = a.contact_id INNER JOIN telephone t
ON     c.contact_id = t.contact_id
AND    a.address_id = t.address_id
WHERE  c.last_name = 'Xavier';

--Step2 Modify the insert_contact definer rights procedure.
BEGIN
insert_contact
( 'Maura'
, 'Jane'
, 'Haggerty'
, 'CUSTOMER'
, 'SLC-000009'
, 'INDIVIDUAL'
, '8888-7777-6666-5555'
, 'MASTER_CARD'
, 'Bangor'
, 'Maine'
, '04401'
, 'HOME'
, '001'
, '207'
, '111-1234'
, 'HOME'
, 'DBA 2');
END;
/

-- Step2 desc insert_contact
DESC insert_contact

-- Step2 verification query.
COL full_name      FORMAT A24
COL account_number FORMAT A10 HEADING "ACCOUNT|NUMBER"
COL address        FORMAT A22
COL telephone      FORMAT A14

SELECT c.first_name
||     CASE
         WHEN c.middle_name IS NOT NULL THEN ' '||c.middle_name||' ' ELSE ' '
       END
||     c.last_name AS full_name
,      m.account_number
,      a.city || ', ' || a.state_province AS address
,      '(' || t.area_code || ') ' || t.telephone_number AS telephone
FROM   member m INNER JOIN contact c
ON     m.member_id = c.member_id INNER JOIN address a
ON     c.contact_id = a.contact_id INNER JOIN telephone t
ON     c.contact_id = t.contact_id
AND    a.address_id = t.address_id
WHERE  c.last_name = 'Haggerty';

--Step3 Modify the insert_contact invoker rights procedure
--into an autonomous insert_contact definer rights function that returns a number.
BEGIN
insert_contact
( 'Harriet'
, 'Mary'
, 'McDonnell'
, 'CUSTOMER'
, 'SLC-000010'
, 'INDIVIDUAL'
, '9999-8888-7777-6666'
, 'VISA_CARD'
, 'Orono'
, 'Maine'
, '04469'
, 'HOME'
, '001'
, '207'
, '111-1234'
, 'HOME'
, 'DBA 2');
END;
/
-- Step3 desc insert_contact
DESC insert_contact

-- Step3 Verification queries.
COL full_name      FORMAT A24
COL account_number FORMAT A10 HEADING "ACCOUNT|NUMBER"
COL address        FORMAT A22
COL telephone      FORMAT A14

SELECT c.first_name
||     CASE
         WHEN c.middle_name IS NOT NULL THEN ' '||c.middle_name||' ' ELSE ' '
       END
||     c.last_name AS full_name
,      m.account_number
,      a.city || ', ' || a.state_province AS address
,      '(' || t.area_code || ') ' || t.telephone_number AS telephone
FROM   member m INNER JOIN contact c
ON     m.member_id = c.member_id INNER JOIN address a
ON     c.contact_id = a.contact_id INNER JOIN telephone t
ON     c.contact_id = t.contact_id
AND    a.address_id = t.address_id
WHERE  c.last_name = 'McDonnell';

--Step4 Create a get_contact object table function
CREATE OR REPLACE TYPE contact_obj IS OBJECT
  ( first_name   VARCHAR2(20)
  , middle_name  VARCHAR2(20)
  , last_name    VARCHAR2(20));
/

  CREATE OR REPLACE TYPE contact_tab IS TABLE OF contact_obj;
/

CREATE OR REPLACE FUNCTION get_contact RETURN CONTACT_TAB IS

  lv_contact_tab CONTACT_TAB := contact_tab();
  CURSOR contacts IS
    SELECT * FROM contact;

BEGIN
  FOR i IN contacts LOOP
      lv_contact_tab.EXTEND;
      lv_contact_tab(lv_contact_tab.LAST) := contact_obj(i.first_name, i.middle_name, i.last_name);
  END LOOP;

  RETURN lv_contact_tab;
END get_contact;
/

--Step4 verification queries.
SET PAGESIZE 999
COL full_name FORMAT A24
SELECT first_name || CASE
                       WHEN middle_name IS NOT NULL
                       THEN ' ' || middle_name || ' '
                       ELSE ' '
                     END || last_name AS full_name
FROM   TABLE(get_contact);


-- Close your log file.
SPOOL OFF
