BEGIN
  EXECUTE IMMEDIATE 'alter user QA7CLARITY501LOOKUPUSER account lock';
  FOR r IN (select sid,serial# from v$session where username='QA7CLARITY501LOOKUPUSER')
  LOOP
      EXECUTE IMMEDIATE 'alter system kill session ''' || r.sid  || ','
        || r.serial# || ''' immediate';
  END LOOP;

    FOR r IN (select sid,serial# from v$session where username='QA7CLARITY501REPORTUSER')
  LOOP
      EXECUTE IMMEDIATE 'alter system kill session ''' || r.sid  || ','
        || r.serial# || ''' immediate';
  END LOOP;

    FOR r IN (select sid,serial# from v$session where username='QA7CLARITY501')
  LOOP
      EXECUTE IMMEDIATE 'alter system kill session ''' || r.sid  || ','
        || r.serial# || ''' immediate';
  END LOOP;
END;
